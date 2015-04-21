class KbmgSyncher
  def initialize
    @kbmg_clients = []
  end

  # Search for events on all campaigns that have the attendance
  # module enabled and fetch try to match each event from KBMG
  # with a event in our application, if a event is found then
  # the RSVPs are synched.
  def synch
    Campaign.where('modules like ?', '%attendance%').each do |campaign|
      if valid_campaign_api_key?(campaign)
        sync_campaign_rsvps campaign
      else
        logger.info "Campaign #{campaign.name} has an invalid API KEY"
      end
    end
  end


  # Synch the RSVPs for a single event. As a requirement, the event's
  # kbmg_event_id attribute should be set to a valid KBMG's Event ID
  def synch_event_rsvps(event)
    kbmg_event = kbmg_client(event.campaign).event(event.kbmg_event_id)
    logger.info "Couldn't fetch event #{event.kbmg_event_id}" unless kbmg_event
    return unless kbmg_event
    registrations = kbmg_client(event.campaign).event_registrations(event.kbmg_event_id)
    logger.info 'Failed to fetch event registrations' unless registrations && registrations['Success']
    return unless registrations && registrations['Success']
    if event.campaign.module_setting('attendance', 'attendance_display') == '2' # Market
      place = kbmg_client(event.campaign).place(kbmg_event['RelatedPlace']['PlaceId'])
      logger.info "Couldn't fetch place #{kbmg_event['RelatedPlace']['PlaceId']}" unless place
      return unless place
      area = event.campaign.areas.where('lower(name) in (?)', [place['City'].downcase, place['MajorMarket'].downcase]).first
      logger.info "Couldn't find an area with name '#{place['City']}' or '#{place['MajorMarket']}'" unless area
      return unless area
      store_event_registrations_at_market event, area, registrations['Data']['Registrations']
    else
      # TODO: implement the synch for campaigns that are not
      # at market level
      logger.info 'Do not how to sync account level campaigns'
    end
  end

  def sync_campaign_rsvps(campaign)
    page = total_pages = 0
    logger.debug "synching #{campaign.name}"
    begin
      logger.debug "fetching results for page #{page}"
      response = kbmg_client(campaign).events(page: page, limit: 1000)
      if response['Success']
        total_pages = (response['Total'] / 1000).to_i + 1
        logger.debug "obtained #{response['Total']} for #{total_pages} pages"
        response['Data']['Events'].each do |kbmg_event|
          events = search_events_in_campaign(campaign, kbmg_event)
          if events.count == 1
            event = events.first
            event.update_column(:kbmg_event_id, kbmg_event['EventId'])
            synch_event_rsvps event
          end
        end
        page += 1
      else
        log_api_error response
      end
    end while page < total_pages && response['Success']
  end

  def search_for_kbmg_event
    results = kbmg_client.events(
      search_string: "StartDate>=#{event.start_at.strftime('%Y-%m-%d')}"\
                     'AND'\
                     "StartDate<=#{(event.start_at + 1.day).strftime('%Y-%m-%d')}")
    return unless results && results.any?
    kbmg_event = results.first
    event.update_column(:kbmg_event_id, event['EventId'])
    kbmg_event
  end

  def store_event_registrations_at_market(event, area, registrations)
    invite = event.invites.find_or_create_by(area: area)
    registrations.each do |registration|
      person = kbmg_client(event.campaign).person(registration['PersonId'])
      next unless person
      rsvp = invite.rsvps.find_or_initialize_by(email: person['Email'])
      update_rsvp_attributes rsvp, registration, person
    end
    invite.update_attributes(
      rsvps_count: invite.rsvps.count,
      attendees: invite.rsvps.where(attended: true).count,
      invitees: 1
    ) unless invite.updated_by_id.present?
  end

  # Search for a campaign event by looking for the start date. Returns
  # an Active Record collection with all events found
  def search_events_in_campaign(campaign, kbmg_event)
    date = Timeliness.parse(kbmg_event['StartDate'], format: 'yyyy-mm-ddThh:nn:ss', zone: :utc)
    campaign.events.where(local_start_at: date.beginning_of_day..date.end_of_day)
  end

  def update_rsvp_attributes(rsvp, registration, person)
    return if rsvp.updated_by_id.present? # Do not update if it was modified by a user
    rsvp.update_attributes(
      first_name: person['FirstName'],
      zip_code: person['PostalCode'],
      date_of_birth: person['DateOfBirth'],
      date_added: person['CreatedDate'],
      attended: registration['Attended'],
      opt_in_to_future_communication: person['IsOptedOut']
    )
  end

  def kbmg_client(campaign)
    return if campaign.module_setting('attendance', 'api_key').blank?
    @kbmg_clients[campaign.id] ||= KBMG.new(campaign.module_setting('attendance', 'api_key'))
  end

  def valid_campaign_api_key?(campaign)
    kbmg_client(campaign) && test_api_call(campaign)
  end

  def logger
    Rails.logger
  end

  def log_api_error(response)
     logger.info "Failed to fetch the results with error: #{response['Error']['ErrorCode']} #{response['Error']['ErrorMessage']}. #{response['Error']['ExceptionMessage']}"
  end

  # Tests the API key by performing a test call and checking for the error code
  def test_api_call(campaign)
    client = kbmg_client(campaign)
    return false unless client
    result = client.events(limit: 1)
    result['Success'] != false || result['Error']['ErrorCode'] != 'API01'
  end
end