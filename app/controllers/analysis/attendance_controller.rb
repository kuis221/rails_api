class Analysis::AttendanceController < ApplicationController
  include ExportableController

  helper_method :return_path, :neighborhood_coordinates, :default_color, :campaign_events

  before_action :collection, only: [:map]

  protect_from_forgery except: :map

  def map
  end

  protected

  def collection_to_csv
    CSV.generate do |csv|
      csv << ['NEIGHBORHOOD', 'CITY', 'STATE', 'ATTENDEES', 'ACCOUNTS ATTENDED', 'INVITATIONS']
      each_collection_item do |neighborhood|
        csv << [neighborhood.name, neighborhood.city, neighborhood.state,
                neighborhood.attendees, neighborhood.attended, neighborhood.invitations]
      end
    end
  end

  def collection
    if event.campaign.module_setting('attendance', 'attendance_display') == '2'
      collection_for_market_level
    else
      collection_for_venue_level
    end
  end

  def collection_for_venue_level
    @neighborhoods =
      Neighborhood.where(events: { id:  event.id })
      .joins(places_join)
      .joins('LEFT JOIN venues ON venues.place_id=places.id')
      .joins('INNER JOIN (SELECT * FROM invites '\
             'INNER JOIN events ON invites.event_id=events.id AND invites.active=\'t\' '\
             'AND events.campaign_id=' + event.campaign_id.to_s + ') invites '\
             'ON invites.venue_id=venues.id')
      .joins('INNER JOIN events ON events.id=invites.event_id')
      .group('neighborhoods.gid')
      .select('neighborhoods.*, COALESCE(sum(invitees), 0) invitations, COALESCE(sum(attendees), 0) attendees,'\
              '0 attended, sum(rsvps_count) rsvps').to_a
  end

  def collection_for_market_level
    populate_zipcode_locations_for_event
    @neighborhoods =
      Neighborhood.where(invites: { event_id:  event.id })
      .joins('INNER JOIN zipcode_locations zl ON zl.neighborhood_id=gid')
      .joins('INNER JOIN invite_rsvps ON zl.zipcode=invite_rsvps.zip_code')
      .joins('INNER JOIN invites ON invite_rsvps.invite_id=invites.id AND invites.event_id= ' + event.id.to_s)
      .group('neighborhoods.gid')
      .select('neighborhoods.*, count(invite_rsvps.id) rsvps, '\
              'sum(CASE WHEN invite_rsvps.attended = \'t\' THEN 1 ELSE 0 END) attendees'
             ).to_a
  end

  def event
    @event ||= Event.accessible_by_user(current_company_user)
                .where(campaign_id: params[:campaign_id]).find(params[:event_id])
  end

  def populate_zipcode_locations_for_event
    InviteRsvp.for_event(event).without_locations.where.not(zip_code: nil)
      .where.not(zip_code: '')
      .pluck('DISTINCT invite_rsvps.zip_code').each do |zipcode|
      next unless zipcode.match(/\A[0-9]{5}(-[0-9]+)?\z/)
      InviteRsvp.update_zip_code_location(zipcode)
    end
  end

  def default_color
    color = current_company.campaigns.find(params[:campaign_id]).color unless params[:campaign_id].blank?
    color = params[:color] if color.blank?
    color = '#347B9B' if color.blank?
    color
  end

  def places_join
    if params[:area_id].blank?
      'LEFT JOIN places'
    else
      Place.connection.unprepared_statement do
        "LEFT JOIN (#{Place.in_areas(Array(params[:area_id])).to_sql}) places"
      end
    end + ' ON ST_Intersects(places.lonlat, neighborhoods.geog)'
  end

  def neighborhood_coordinates(neighborhood)
    return '' if neighborhood.nil? || neighborhood.geog.nil?
    neighborhood.geog[0].exterior_ring.points.map do |point|
      "new google.maps.LatLng(#{point.lat}, #{point.lon})"
    end.join(',')
  end

  def list_exportable?
    true
  end

  def campaign_events
    if params[:campaign_id].blank?
      []
    else
      current_company.campaigns.find(params[:campaign_id]).event_dates
    end
  end

  def return_path
    analysis_path
  end
end
