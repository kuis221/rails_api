class Analysis::AttendanceController < ApplicationController
  include ExportableController

  helper_method :return_path, :neighborhood_coordinates, :default_color, :campaign_events

  before_action :collection, only: [:map]

  protect_from_forgery except: :map

  def map
  end

  protected

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
      .joins('INNER JOIN zipcode_locations ON ST_Intersects(zipcode_locations.lonlat, neighborhoods.geog)')
      .joins('INNER JOIN invite_rsvps ON zipcode_locations.zipcode=invite_rsvps.zip_code')
      .joins('INNER JOIN invites ON invite_rsvps.invite_id=invites.id')
      .group('neighborhoods.gid')
      .select('neighborhoods.*, COALESCE(sum(invitees), 0) invitations, count(invite_rsvps.id) attendees,'\
              'sum(CASE WHEN invite_rsvps.attended = \'t\' THEN 1 ELSE 0 END) attended, sum(rsvps_count) rsvps').to_a
  end

  def event
    @event ||= Event.accessible_by_user(current_company_user)
                .where(campaign_id: params[:campaign_id]).find(params[:event_id])
  end

  def populate_zipcode_locations_for_event
    InviteRsvp.for_event(event).without_locations.where.not(zip_code: nil)
      .where.not(zip_code: '')
      .pluck('DISTINCT invite_rsvps.zip_code').each do |zipcode|
        latlng = get_latlng_for_zip_code(zipcode)
        InviteRsvp.update_zip_code_location(zipcode, latlng) if latlng
    end
  end

  def get_latlng_for_zip_code(zipcode)
    data = JSON.parse(open(
            'https://maps.googleapis.com/maps/api/geocode/json?components='\
            "postal_code:#{zipcode}|country:US&sensor=true").read)
    data['results'].first['geometry']['location'] rescue nil
  end

  def default_color
    color = current_company.campaigns.find(params[:campaign_id]).color unless params[:campaign_id].blank?
    color ||= params[:color] unless params[:color].blank?
    color ||= '#347B9B'
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
