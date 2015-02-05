module JbbFile
  class JamesonLocalsAccount < JbbFile::Base
    VALID_COLUMNS = ['TDLinx Code', 'Name', 'Address', 'City', 'State']

    def initialize
      self.ftp_server   = ENV['TDLINX_FTP_SERVER']
      self.ftp_username = ENV['TDLINX_FTP_USERNAME']
      self.ftp_password = ENV['TDLINX_FTP_PASSWORD']
      self.ftp_folder   = ENV['JAMESON_LOCALS_FTP_FOLDER']
      self.invalid_files = []

      self.mailer = JbbJamesonLocalsAccountMailer
    end

    def process
      @created = @existed = 0
      Dir.mktmpdir do |dir|
        files = download_files(dir)
        return invalid_format if invalid_files.any?
        return unless files.any?

        flagged_before = Venue.jameson_locals.in_company(COMPANY_ID).count
        ActiveRecord::Base.transaction do
          reset_jameson_venue_flag
          files.each do |file|
            venue_ids = []
            each_sheet(file[:excel]) do |sheet|
              sheet.each(td_linx_code: 'TDLinx Code', name: 'Name', route: 'Address', city: 'City', state: 'State')  do |row|
                next if row[:name] == 'Name'
                row[:td_linx_code] = row[:td_linx_code].to_s.gsub(/\.0\z/, '')
                row[:state] = Place.state_name('US', row[:state]) if row[:state] =~ /[A-Z][A-Z]/i
                venue_ids.push find_or_create_venue(row)
              end
            end
            Venue.where(id: venue_ids.compact).update_all(jameson_locals: true)
          end
        end

        total_flagged = Venue.jameson_locals.in_company(COMPANY_ID).count
        success total_flagged, @existed, @created, flagged_before,
                Hash[files.map { |f| [f[:file_name], f[:path]] }]

        files.each { |file| archive_file file[:file_name] }
        self
      end
    ensure
      close_connection
    end

    def success(total, existed, created, flagged_before, files)
      mailer.success(total, existed, created, flagged_before, files).deliver
      false
    end

    def reset_jameson_venue_flag
      Venue.where(company_id: COMPANY_ID, jameson_locals: true).update_all(jameson_locals: false)
    end

    def find_or_create_venue(attrs)
      place = Place.joins("LEFT JOIN venues ON places.id=venues.place_id AND venues.company_id=#{COMPANY_ID}")
           .select('places.*, venues.id as venue_id')
           .where(td_linx_code: attrs[:td_linx_code])
           .first
      if place
        @existed += 1
        place.venue_id || Venue.create(place_id: place.id, company_id: COMPANY_ID).try(:id)
      else
        id = find_place_by_address(attrs)
        if id
          @existed += 1
          Venue.find_or_create_by(place_id: id, company_id: COMPANY_ID).try(:id)
        else
          @created += 1
          create_place_and_venue(attrs).try(:id)
        end
      end
    end

    def find_place_by_address(attrs)
      Place.find_place(name: attrs[:name], street: attrs[:route],
          city: attrs[:city], zipcode: nil,
          state: attrs[:state])
    end

    def create_place_and_venue(attrs)
      attrs[:city] = attrs[:city].titleize if attrs[:city].present?
      attrs[:state] = attrs[:city].titleize if attrs[:city].present?
      place = Place.create(attrs.merge(
        is_custom_place: true,
        types: ['establishment'], country: 'US'))
      Venue.create(place_id: place.id, company_id: COMPANY_ID)
    end
  end
end
