require 'net/ftp'
require 'zip'
require 'open-uri'
require 'tempfile'

module TdLinxSynch
  class Processor
    attr_accessor :csv_path

    def self.download_and_process_file(file)
      path = file || 'tmp/td_linx_code.csv'
      download_file(path) unless file
      process(path)
    rescue => e
      logger.error "Something wrong happened in the process: #{e.message}"
      TdlinxMailer.td_linx_process_failed(e).deliver
      raise e # Raise the error so we see it on errbit
    end

    def self.process(path)
      paths = {
        master_only: 'tmp/td_master_only.csv',
        brandscopic_only: 'tmp/brandscopic_only.csv',
        found: 'tmp/found_and_updated.csv',
        found_not_updated: 'tmp/found_not_updated.csv',
        missing: 'tmp/missing.csv'
      }

      # Create and open all CSV files
      files = Hash[paths.map { |k, p| [k, CSV.open(p, 'w')] }]

      # Here it comes... read each line in the downloaded CSV file
      # and look for a match in the database
      logger.info "Start processing #{path}"
      i = 0
      CSV.foreach(path) do |row|
        row[2].gsub!(/,\s*#{row[3]}\s*,\s*#{row[4]}\s*,\s*#{row[5]}\s*/, '')
        row[2].gsub!(/\A\s*#{row[1]}\s*,?\s*/, '')
        if place_id = find_place_for_row(row)
          place = Place.find(place_id)
          if place.td_linx_code != row[0]
            files[:found] << row + [place.td_linx_code]
            place.update_column(:td_linx_code, row[0])
          else
            files[:found_not_updated] << row
          end
        else
          files[:master_only] << row
        end
        i+=1
        logger.info "#{i} rows processed" if (i % 500) == 0
      end

      # Search for establishments related to venues in LegacyCompany that doesn't
      # have a code and add it to missing.csv file
      logger.info "Looking for venues without TD Linx Code"
      files[:missing] << ['Venue Name', 'Street', 'City', 'State', 'Zip Code', '# Events']
      Place.joins(:venues).joins('LEFT JOIN events ON events.place_id=places.id')
        .select('places.*, count(events.id) as visits_count')
        .group('places.id')
        .where('venues.company_id=2 AND td_linx_code is null')
        .where('types like \'%establishment%\'')
        .find_each do |place|
        files[:missing] << [
          place.name, place.street, place.city, place.state,
          place.zipcode, place.visits_count]
      end
      files.values.each(&:close)

      logger.info "Creating ZIP file with results"
      zip_path = Dir::Tmpname.make_tmpname('tmp/tdlinx_', nil)
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
        paths.values.each { |p|  zip.add(File.basename(p), p) }
      end

      logger.info "Delivering email with results"
      TdlinxMailer.td_linx_process_completed(zip_path).deliver

      files = {}
      File.delete zip_path
      logger.info "Process completed!!"
      paths
    ensure
      files.values.each { |f| f.close rescue true }
    end

    def self.find_place_for_row(row)
      Place.find_tdlinx_place(name: row[1].try(:strip), street: row[2].try(:strip), city: row[3].try(:strip),
        state: state_name(row[4].try(:strip)), zipcode: row[5].try(:strip))
    end

    def self.logger
      Rails.logger
    end

    def self.state_name(state_code)
      state_code.match(/\A[A-Z]{2}\z/i) ? country.states[state_code]['name'] : state_code
    end

    def self.country
      @country ||= Country.new('US')
    end

    def self.download_file(path)
      ftp = Net::FTP.new(ENV['TDLINX_FTP_SERVER'])
      ftp.passive = true
      ftp.login(ENV['TDLINX_FTP_USERNAME'], ENV['TDLINX_FTP_PASSWORD'])
      ftp.chdir(ENV['TDLINX_FTP_FOLDER']) if ENV['TDLINX_FTP_FOLDER']
      file = ftp.list('Legacy_TDLINX_Store_Master*').map { |l| l.split(/\s+/, 4) }.sort_by { |a| a[0] }.first
      fail 'Could not find a proper file for download from FTP' unless file.present?

      date = Timeliness.parse(file[0], :date, format: 'mm-dd-yy').to_date
      fail "The latest file (#{file[3]}) in the FTP have more than 30 days old" if date < 30.days.ago
      Rails.logger.info "TDLINX: Downloading FTP file #{file[3]}"
      begin
        ftp.gettextfile file[3], path
      rescue Exception => e
        raise "An error has occurred when trying to download the file #{file[3]} from the FTP server: #{e.message}"
      end
    ensure
      ftp.close if ftp && !ftp.closed?
    end
  end
end
