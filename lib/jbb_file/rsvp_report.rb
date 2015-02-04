module JbbFile
  class RsvpReport < JbbFile::Base
    COLUMNS = {
      market: 'Market',
      final_date: 'FinalDate',
      event_date: 'EventDate',
      registrant_id: 'RegistrantId',
      date_added: 'DateAdded',
      email: 'Email',
      mobile_phone: 'MobilePhone',
      mobile_signup: 'MobileSignup',
      first_name: 'FirstName',
      last_name: 'lastName',
      account_name: 'AccountName',
      attended_previous_bartender_ball: 'AttendedPreviousBartenderBall',
      opt_in_to_future_communication: 'OptInToFutureCommunication',
      primary_registrant_id: 'PrimaryRegistrantId',
      bartender_how_long: 'BartenderHowLong',
      bartender_role: 'BartenderRole'
    }

    INVITE_COLUMNS = [:market, :final_date]

    RSVP_COLUMNS = COLUMNS.keys - INVITE_COLUMNS - [:account_name, :event_date]

    VALID_COLUMNS = COLUMNS.values

    CAMPAIGN_ID = 210

    attr_accessor :created, :failed, :multiple_events

    def initialize
      self.ftp_server    = ENV['TDLINX_FTP_SERVER']
      self.ftp_username  = ENV['TDLINX_FTP_USERNAME']
      self.ftp_password  = ENV['TDLINX_FTP_PASSWORD']
      self.ftp_folder    = ENV['RSVP_REPORT_FTP_FOLDER']
      self.invalid_files = []

      self.mailer = RsvpReportMailer
    end

    def process
      self.created = self.failed = self.multiple_events = 0
      invalid_rows = []
      Dir.mktmpdir do |dir|
        files = download_files(dir)
        return invalid_format if invalid_files.any?
        return unless files.any?

        ActiveRecord::Base.transaction do
          files.each do |file|
            each_sheet(file[:excel]) do |sheet|
              sheet.each(COLUMNS) do |row|
                next if row[:final_date] == 'FinalDate'
                event = find_event_for_row(row)
                venue = find_venue(row) if event
                if venue && event
                  invite = event.invites.create_with(
                    row.select { |k, _| INVITE_COLUMNS.include?(k) }.merge(venue_id: venue.id)
                  ).find_or_create_by(venue_id: venue.id)
                  if invite.rsvps.create(row.select { |k, _| RSVP_COLUMNS.include?(k) })
                    invite.increment!(:rsvps_count)
                  end
                  self.created += 1
                else
                  p "INVALID EVENT OR VENUE #{venue.inspect} #{event.inspect}"
                  invalid_rows.push row
                end
              end
            end
          end

          p 'ENDED!'
        end

        files.each { |file| archive_file file[:file_name] }

        success created, invalid_rows.count, multiple_events, invalid_rows
      end
    ensure
      close_connection
    end

    def area(name)
      @areas ||= {}
      @areas[name] ||= Area.find_by(name: name)
      @areas[name]
    end

    def find_event_for_row(row)
      @events ||= {}
      date = Timeliness.parse(row[:event_date].split[0], format: 'm/d/yyyy', zone: :current)
      date_str = date.to_date.to_s(:db)
      scope = campaign.events.where('events.local_start_at::date=?', date_str).active
      return @events[date_str] unless @events[date_str].nil?
      if scope.count > 1
        self.multiple_events += 1
        return
      end
      @events[date_str] ||= scope.first
      @events[date_str] ||= create_event(date, row[:market])
      @events[date_str]
    end

    def create_event(date, city)
      place = find_city(city)
      return unless place.present?
      p (date + 1.day).to_s(:slashes)
      event = campaign.events.create(
        company: campaign.company,
        start_date: date.to_s(:slashes),
        end_date: (date + 1.day).to_s(:slashes),
        start_time: '9:00pm',
        end_time: '12:00am',
        place_reference: place.reference + '||' + place.place_id)
      return unless event.persisted?
      event
    end

    def find_city(city)
      Place.google_client.spots_by_query(city, types: [:political, :natural_feature]).first
    end

    def success(created, failed, multiple_events, invalid_rows)
      path = "#{Rails.root}/tmp/invalid_rows.csv"
      CSV.open(path, 'wb') do |csv|
        csv << COLUMNS.values
        invalid_rows.each { |row| p row.inspect;  csv << row.values; }
      end if invalid_rows.any?
      mailer.success(created, failed, multiple_events, (invalid_rows.any? ? [path] : nil)).deliver
      false
    end

    def find_venue(attrs)
      place = find_place_in_database(attrs[:account_name], attrs[:market])
      place ||= find_place_in_google_api(attrs[:account_name], attrs[:market])
      return unless place.present?
      p "Found #{place.name} for #{attrs[:account_name]}"
      Venue.find_or_create_by(company_id: COMPANY_ID, place_id: place.id)
    end

    def find_place_in_database(name, city_or_state)
      a = area(city_or_state)
      base = Place.where('similarity(places.name, :name) > 0.5', name: name)
      base.where('lower(city)=:name OR lower(state)=:name', name: city_or_state.downcase).first ||
      (a && base.in_areas([a]).first)
    end

    def find_place_in_google_api(name, city_or_state)
      p "Searching #{name} near #{city_or_state}, US"
      spot = Place.google_client.spots_by_query("#{name} near #{city_or_state}, US").first
      spot = nil if spot.nil? || spot.name.downcase.similar(name) < 50
      p "NOT FOUND" if spot.nil?
      return unless spot.present?
      place = Place.load_by_place_id(spot.place_id, spot.reference)
      place.save unless place.persisted?
      place
    rescue => e
      p "Error in request: #{e.message}"
      nil
    end

    def campaign
      @campaign ||= Company.find(COMPANY_ID).campaigns.find(CAMPAIGN_ID)
    end
  end
end