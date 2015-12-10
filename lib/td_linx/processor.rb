require 'net/ftp'
require 'zip'
require 'open-uri'
require 'tempfile'

module TdLinx
  class Processor
    attr_accessor :csv_path

    CONFIDENCE_LEVELS = {
      '10' => 'High',
      '7' => 'Manual',
      '5' => 'Medium',
      '1' => 'Low'
    }

    def self.download_and_process_file(file, company_id = 2)
      @company_id = company_id
      path = file || 'tmp/td_linx_code.csv'
      download_file(path) unless file
      prepare_codes_table path   # creates a table from file
      process!
    rescue => e
      logger.error "Something wrong happened in the process: #{e.message}"
      TdlinxMailer.td_linx_process_failed(e).deliver
      raise e # Raise the error so we see it on errbit
      # ensure
      #   drop_tdlinx_codes_table
    end

    def self.process!
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
      logger.info 'Start processing venues'
      i = 0
      Place.joins(:venues).joins('LEFT JOIN events ON events.place_id=places.id')
        .select('places.*, venues.id venue_id, count(events.id) as events_count')
        .group('places.id, venues.id').order('places.id ASC')
        .where('venues.company_id=? AND places.is_location=?', @company_id, false).each do |place|
        next if place.types.present? && place.types.include?('street_address')

        row = place.td_linx_match
        if row.present? && row['code'].present?
          if place.td_linx_code != row['code'] && (place.td_linx_confidence.nil? || place.td_linx_confidence < row['confidence'].to_i)
            files[:found] << row.merge(
                               'confidence' => CONFIDENCE_LEVELS[row['confidence']]
                             ).values +
                             [place.td_linx_code,
                              'http://login.brandscopic.com/research/venues/' + place.venue_id.to_s]
            place.update_columns(td_linx_code: row['code'], td_linx_confidence: row['confidence'])
          else
            if place.td_linx_code == row['code'] && place.td_linx_confidence != row['confidence'].to_i
              place.update_column(:td_linx_confidence, row['confidence'])
            end
            files[:found_not_updated] << row.values
          end
        else
          files[:missing] << [
            place.name, place.street, place.city, place.state,
            place.zipcode, place.events_count] unless place.td_linx_code
        end
        i += 1
        logger.info "#{i} rows processed" if (i % 500) == 0
      end

      files.values.each(&:close)

      logger.info 'Creating ZIP file with results'
      zip_path = Dir::Tmpname.make_tmpname('tmp/tdlinx_', nil)
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
        paths.values.each { |p|  zip.add(File.basename(p), p) }
      end

      logger.info 'Delivering email with results'
      TdlinxMailer.td_linx_process_completed(zip_path).deliver

      files = {}
      File.delete zip_path
      logger.info 'Process completed!!'
      paths
    ensure
      files.values.each { |f| f.close rescue true }
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

    def self.create_tdlinx_codes_table
      return if ActiveRecord::Base.connection.table_exists? 'tdlinx_codes'
      ActiveRecord::Base.connection.execute(
        'CREATE TABLE IF NOT EXISTS tdlinx_codes('\
          'td_linx_code varchar, name varchar, street varchar, '\
          'city varchar, state varchar, zipcode varchar)')
      logger.info 'TDLINX: Creating indexes on tdlinx_codes table'
      ActiveRecord::Base.connection.execute(
        'CREATE INDEX td_linx_code_state_idx on tdlinx_codes (state)')
      ActiveRecord::Base.connection.execute(
        'CREATE INDEX td_linx_code_norm_name_idx on tdlinx_codes (normalize_place_name(name))')
      ActiveRecord::Base.connection.execute(
        'CREATE INDEX td_linx_code_substr_name_idx on tdlinx_codes (substr(lower(name), 1, 5))')
      ActiveRecord::Base.connection.execute(
        'CREATE INDEX td_linx_code_substr_street_idx on tdlinx_codes (substr(lower(street), 1, 5))')
      ActiveRecord::Base.connection.execute(
        'CREATE INDEX td_linx_code_substr_zipcode_idx on tdlinx_codes (substr(zipcode, 1, 2))')
      ActiveRecord::Base.connection.execute(
        'CREATE INDEX td_linx_full_name_trgm_idx ON tdlinx_codes USING gist (name gist_trgm_ops)')
      ActiveRecord::Base.connection.execute(
        'CREATE INDEX td_linx_full_street_trgm_idx ON tdlinx_codes USING gist (street gist_trgm_ops)')
    end

    def self.prepare_codes_table(path)
      drop_tdlinx_codes_table
      create_tdlinx_codes_table
      load_data_into_tmp_table path
    end

    def self.load_data_into_tmp_table(path)
      copy_data_from_file path
      # ActiveRecord::Base.connection.execute(
      #   "COPY tdlinx_codes(td_linx_code,name,street,city,state,zipcode) FROM '#{path}' DELIMITER ',' CSV")
      logger.info 'TDLINX: Preparing imported data'
      ActiveRecord::Base.connection.execute(
        'UPDATE tdlinx_codes SET street=normalize_addresss(street)')
      ActiveRecord::Base.connection.execute(
       'UPDATE tdlinx_codes SET street=regexp_replace('\
         "street, ',\\s*' || city || '\\s*,\\s*' || state || '\\s*,\\s*' || zipcode || '\\s*', "\
         "'')::varchar")
      ActiveRecord::Base.connection.execute(
        "UPDATE tdlinx_codes SET street=regexp_replace(street, '^\\s*' || name || '\\s*,?\s*', '')::varchar")
    end

    def self.copy_data_from_file(path)
      logger.info 'TDLINX: Loading file data into database'
      dbconn = ActiveRecord::Base.connection_pool.checkout
      raw  = dbconn.raw_connection

      result = raw.copy_data "COPY tdlinx_codes FROM STDIN DELIMITER ',' CSV" do
        File.open(path, 'r').each do |line|
          raw.put_copy_data line
        end
      end

      ActiveRecord::Base.connection_pool.checkin(dbconn)
    end

    def self.drop_tdlinx_codes_table
      ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS tdlinx_codes')
    end

    def self.download_file(path)
      ftp = Net::FTP.new(ENV['TDLINX_FTP_SERVER'])
      ftp.passive = true
      ftp.login(ENV['TDLINX_FTP_USERNAME'], ENV['TDLINX_FTP_PASSWORD'])
      ftp.chdir(ENV['TDLINX_FTP_FOLDER']) if ENV['TDLINX_FTP_FOLDER']
      file = ftp.list('Legacy_TDLINX_Store_Master*').map { |l| l.split(/\s+/, 4) }.sort_by { |a| a[0] }.first
      fail 'Could not find a proper file for download from FTP' unless file.present?

      date = Timeliness.parse(file[0], :date, format: 'mm-dd-yy').to_date
      # fail "The latest file (#{file[3]}) in the FTP have more than 30 days old" if date < 30.days.ago
      logger.info "TDLINX: Downloading FTP file #{file[3]}"
      begin
        ftp.gettextfile file[3], path
      rescue => e
        raise "An error has occurred when trying to download the file #{file[3]} from the FTP server: #{e.message}"
      end
    ensure
      ftp.close if ftp && !ftp.closed?
    end
  end
end
