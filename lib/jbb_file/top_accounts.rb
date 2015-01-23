module JbbFile
  class TopAccounts < JbbFile::Base

    VALID_COLUMNS = ['TDLinx Store Code', 'Retailer', 'City', 'Address', 'State']

    attr_accessor :created, :existed
    def initialize
      self.ftp_server   = ENV['TDLINX_FTP_SERVER']
      self.ftp_username = ENV['TDLINX_FTP_USERNAME']
      self.ftp_password = ENV['TDLINX_FTP_PASSWORD']
      self.ftp_folder   = ENV['TOP_ACCOUNTS_FTP_FOLDER']
      self.invalid_files = []

      self.mailer = TopAccountsMailer
    end

    def process
      self.created = 0
      self.existed = 0
      Dir.mktmpdir do |dir|
        ActiveRecord::Base.transaction do
          files = download_files(dir)
          return invalid_format if invalid_files.any?
          return unless files.any?

          flagged_before = Venue.top_venue.in_company(COMPANY_ID).count
          total_rows = 0

          reset_top_accounts_flag
          files.each do |file|
            p "\n\nProcessing file #{file[:file_name]}"
            venue_ids = []
            each_sheet(file[:excel]) do |sheet|
              sheet.each(td_linx_code: 'TDLinx Store Code', name: 'Retailer',
                         route: 'Address', city: 'City', state: 'State')  do |row|
                next if row[:name] == 'Retailer' # Skip the header
                row[:td_linx_code] = row[:td_linx_code].to_s.gsub(/\.0\z/, '')
                row[:state] = Place.state_name('US', row[:state]) if row[:state] =~ /\A[A-Z][A-Z]\z/i
                venue_ids.push find_or_create_venue(row)
                total_rows += 1
              end
            end
            Venue.where(id: venue_ids.compact).update_all(top_venue: true)
          end

          files.each { |file| archive_file file[:file_name] }

          total_flagged = existed + created
          success total_rows, total_flagged, existed, created, flagged_before,
                  Hash[files.map { |f| [f[:file_name], f[:path]] }]
        end
      end
    ensure
      close_connection
    end

    def success(total, flagged, existed, created, flagged_before, files)
      mailer.success(total, flagged, existed, created, flagged_before, files).deliver
      false
    end

    def reset_top_accounts_flag
      Venue.top_venue.in_company(COMPANY_ID).update_all(top_venue: false)
    end

    def find_or_create_venue(attrs)
      place = Place.joins("LEFT JOIN venues ON places.id=venues.place_id AND venues.company_id=#{COMPANY_ID}")
           .select('places.*, venues.id as venue_id')
           .where(td_linx_code: attrs[:td_linx_code])
           .first
      if attrs[:td_linx_code] && place
        self.existed += 1
        place.venue_id || Venue.create(place_id: place.id, company_id: COMPANY_ID).try(:id)
      else
        p "Venue not found: #{attrs.inspect}"
        id = find_place_by_address(attrs)
        if id
          self.existed += 1
          Venue.find_or_create_by(place_id: id, company_id: COMPANY_ID).try(:id)
        else
          create_place_and_venue(attrs).try(:id)
        end
      end
    end

    def find_place_by_address(attrs)
      Place.find_tdlinx_place(name: attrs[:name], street: attrs[:route],
          city: attrs[:city], zipcode: nil,
          state: attrs[:state])
    end

    def create_place_and_venue(attrs)
      attrs[:city] = attrs[:city].titleize if attrs[:city].present?
      attrs[:state] = attrs[:city].titleize if attrs[:city].present?
      place = Place.create(attrs.merge(is_custom_place: true, country: 'US'))
      self.created += 1
      Venue.create(place_id: place.id, company_id: COMPANY_ID)
    end
  end
end
