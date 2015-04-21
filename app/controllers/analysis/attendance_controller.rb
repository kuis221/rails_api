class Analysis::AttendanceController < ApplicationController
  include ExportableController

  helper_method :return_path, :neighborhood_coordinates, :default_color, :campaign_events

  before_action :collection, only: [:map]

  protect_from_forgery except: :map

  def map
  end

  protected

  def return_path
    results_reports_path
  end

  def collection
    @neighborhoods =
      Neighborhood.where(events: { id:  params[:event_id] })
      .joins(places_join)
      .joins('LEFT JOIN venues ON venues.place_id=places.id')
      .joins('INNER JOIN (SELECT * FROM invites INNER JOIN events ON invites.event_id=events.id AND invites.active=\'t\' AND events.campaign_id=' + params[:campaign_id].to_i.to_s + ') invites ON invites.venue_id=venues.id')
      .joins('INNER JOIN events ON events.id=invites.event_id')
      .group('neighborhoods.gid')
      .select('neighborhoods.*, COALESCE(sum(invitees), 0) invitations, COALESCE(sum(attendees), 0) attendees,'\
              '0 attended, sum(rsvps_count) rsvps').to_a
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
        "LEFT JOIN (#{Place.in_areas(params[:area_id]).to_sql}) places"
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
end
