require 'net/ftp'
require 'zip'

module TdLinxSynch
  class Processor
    attr_accessor :csv_path

    def self.download_and_process_file
      path = 'tmp/td_linx_code.csv'
      self.download_file(path)
      self.process(path)
    rescue Exception => e
      TdlinxMailer.td_linx_process_failed(e).deliver
      raise e # Raise the error so we see it on errbit
    end

    def self.process(path)
      paths = {
        master_only: 'tmp/td_master_only.csv',
        brandscopic_only: 'tmp/brandscopic_only.csv',
        found: 'tmp/found_and_updated.csv',
        found_not_updated: 'tmp/found_not_updated.csv',
        missing: 'tmp/missing.csv',
      }

      # Create and open all CSV files
      files = Hash[paths.map{|k, path| [k, CSV.open(path, 'w')]}]

      # Here it comes... read each line in the downloaded CSV file
      # and look for a match in the database
      CSV.foreach(path) do |row|
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
      end

      # Search for establishments related to venues in LegacyCompany that doesn't
      # have a code and add it to missing.csv file
      files[:missing] << ['Venue Name', 'Street', 'City', 'State', 'Zip Code', '# Events']
      Place.joins(:venues).joins('LEFT JOIN events ON events.place_id=places.id')
           .select('places.*, count(events.id) as visits_count')
           .group('places.id')
           .where('venues.company_id=2 AND td_linx_code is null')
           .where('types like \'%establishment%\'')
           .find_each do |place|
        files[:missing] << [place.name, place.street, place.city, place.state, place.zipcode, place.visits_count]
      end

      files.each{|k, file| file.close() }

      zip_path = Dir::Tmpname.make_tmpname('tmp/tdlinx_', nil)
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
        paths.each{|k, path|  zip.add(File.basename(path), path) }
      end

      TdlinxMailer.td_linx_process_completed(path).deliver

      files = {}
      paths
    ensure
      files.each{|k, file| file.close() }
    end

    def self.find_place_for_row(row)
      Place.find_tdlinx_place(name: row[1], street: row[2], city: row[3],
        state: state_name(row[4]), zipcode: row[5])
    end

    def self.state_name(state_code)
      country.states[state_code]['name']
    end

    protected
      def self.country
        @country ||= Country.new('US')
      end

      def self.download_file(path)
        ftp = Net::FTP.new(ENV['TDLINX_FTP_SERVER'])
        tp.passive = true
        ftp.login(ENV['TDLINX_FTP_USERNAME'], ENV['TDLINX_FTP_PASSWORD'])
        file = ftp.list('Legacy_TDLINX_Store_Master*').map{|l| l.split(/\s+/, 4) }.sort{ |a, b| b[0] <=> a[0]}.first
        if file.present?
          ftp.gettextfile file[3], path
        end
        ftp.close
      end
  end
end
