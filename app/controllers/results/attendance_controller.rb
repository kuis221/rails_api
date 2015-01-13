class Results::AttendanceController < ApplicationController
  helper_method :return_path, :neighborhood_coordinates

  before_action :load_neighborhoods, only: [:map]

  def index
    @states = Country.new('US').states.map { |code, data| ["#{code} (#{data['name']})", data['name']] }
  end

  def map
  end

  protected

  def return_path
    results_reports_path
  end

  def load_neighborhoods
    @neighborhoods =
      Neighborhood.where(country: 'US', state: params[:state], city: params[:city])
      .joins('LEFT JOIN (select id, state, city, country, unnest(neighborhoods) neighborhood
                         FROM places WHERE neighborhoods is not null) places ON places.city=neighborhoods.city AND
                        places.state=neighborhoods.state AND
                        places.country=neighborhoods.country AND
                        similarity(lower(neighborhoods.name), lower(places.neighborhood)) >= 0.8')
      .joins('LEFT JOIN venues ON venues.place_id=places.id')
      .joins('LEFT JOIN invites ON invites.venue_id=venues.id')
      .group('neighborhoods.id')
      .select('neighborhoods.*, count(invites) invitations')
  end

  def neighborhood_coordinates(neighborhood)
    JSON.parse(neighborhood.geometry)['coordinates'].first.map do |coordinate|
      "new google.maps.LatLng(#{coordinate[1]}, #{coordinate[0]})"
    end.join(',')
  end
end
