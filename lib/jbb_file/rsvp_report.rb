module JbbFile
  class RsvpReport < JbbFile::Base
    COLUMNS = {
      campaign: 'Campaign Name',
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

    RSVP_COLUMNS = COLUMNS.keys - INVITE_COLUMNS - [:account_name, :event_date, :campaign]

    VALID_COLUMNS = COLUMNS.values

    attr_accessor :created, :failed, :multiple_events

    def initialize
      self.ftp_server    = ENV['TDLINX_FTP_SERVER']
      self.ftp_username  = ENV['TDLINX_FTP_USERNAME']
      self.ftp_password  = ENV['TDLINX_FTP_PASSWORD']
      self.ftp_folder    = ENV['RSVP_REPORT_FTP_FOLDER']
      self.invalid_files = []

      @areas = {}
      @campaigns = {}

      self.mailer = RsvpReportMailer
    end

    def process
      puts "RsvpReport.process STARTED!"
      self.created = self.failed = self.multiple_events = 0
      invalid_rows = []
      Dir.mktmpdir do |dir|
        files = download_files(dir)
        return invalid_format if invalid_files.any?
        return unless files.any?
        files.each do |file|
          ActiveRecord::Base.transaction do
            each_sheet(file[:excel]) do |sheet|
              sheet.each(self.class::COLUMNS) do |row|
                next if row[:final_date] == 'FinalDate'
                campaign = find_campaign(row)
                market_level = campaign.module_setting('attendance', 'attendance_display') == '2' if campaign
                event = find_event_for_row(campaign, row) if campaign
                area = find_area(campaign, row) if event && market_level
                venue = find_venue(row) unless market_level || event.nil?
                if (market_level || venue) && event && (!market_level || area)
                  invite_scope_params = market_level ? { area_id: area.id } : { venue_id: venue.id }
                  invite = event.invites.create_with(
                    row.select { |k, _| self.class::INVITE_COLUMNS.include?(k) }.merge(invite_scope_params)
                  ).find_or_create_by(invite_scope_params)
                  next unless invite.persisted?
                  if invite.rsvps.create(row.select { |k, _| self.class::RSVP_COLUMNS.include?(k) })
                    invite.increment!(:rsvps_count)
                  end
                  self.created += 1
                else
                  p "INVALID EVENT OR VENUE #{event.inspect} #{venue.inspect} #{area}"
                  invalid_rows.push row
                end
              end
            end
            archive_file file[:file_name]
          end
        end
        p 'ENDED!'

        success created, invalid_rows.count, multiple_events, invalid_rows
      end
    ensure
      close_connection
    end

    def area(name)
      @areas ||= {}
      @areas[name] ||= company.areas.find_by(name: name)
      @areas[name]
    end

    def find_event_for_row(campaign, row)
      @events ||= {}
      date =
        if row[:event_date].is_a?(String)
          Timeliness.parse(row[:event_date].split[0], format: 'm/d/yyyy', zone: :current)
        else
          row[:event_date]
        end
      return if date.blank?
      date_str = date.to_date.to_s(:db)
      date_str_with_market_name = "#{date_str}-#{row[:market]}"
      return @events[date_str_with_market_name] unless @events[date_str_with_market_name].nil?

      if campaign.areas.where('lower(name) = ?', row[:market].strip).exists?
        event_scope = campaign.events.where('events.local_start_at::date=?', date_str).active
        if event_scope.count > 1
          self.multiple_events += 1
          return
        end
        @events[date_str_with_market_name] ||= event_scope.first
      end

      @events[date_str_with_market_name] ||= create_event(campaign, date, row[:market])
      @events[date_str_with_market_name]
    end

    def create_event(campaign, date, city)
      place = find_city(city)
      return unless place.present?
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
      company.venues.find_or_create_by(place_id: place.id)
    end

    def find_area(campaign, attrs)
      return unless attrs[:market]
      @areas[attrs[:market]] ||= campaign.areas.where('lower(name)=?', attrs[:market].downcase.strip).first
    end

    def find_campaign(attrs)
      return unless attrs[:campaign]
      @campaigns[attrs[:campaign]] ||= company.campaigns.where('lower(name)=?', attrs[:campaign].downcase.strip).first
    end

    def find_place_in_database(name, city_or_state)
      a = area(city_or_state)
      base = Place.select("similarity(places.name, #{Place.connection.quote(name)}), places.*").where('similarity(places.name, :name) > 0.5', name: name).order('1 DESC')
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
  end
end
