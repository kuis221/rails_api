class Results::AttendanceController < ApplicationController
  helper_method :return_path, :neighborhood_coordinates

  def index
    @states = Country.new('US').states.map { |code, data| ["#{code} (#{data['name']})", data['name']] }
  end

  def map
    @neighborhoods = Neighborhood.where(country: 'US', state: params[:state], city: params[:city])
  end

  def return_path
    results_reports_path
  end

  def neighborhood_coordinates(neighborhood)
    JSON.parse(neighborhood.geometry)['coordinates'].first.map do |coordinate|
      "new google.maps.LatLng(#{coordinate[1]}, #{coordinate[0]})"
    end.join(',')
  end
end
