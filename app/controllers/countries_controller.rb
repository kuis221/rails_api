# Countries Controller class
#
# This class handle the requests for managing the Countries
#
class CountriesController < ApplicationController
  skip_before_action :authenticate_user!

  def states
    @country = Country.new(params[:country]) if params[:country].present?
  end

  def cities
    country = params[:id]
    state = params[:state]
    if country && state
      render json: Place.where(country: country, state: state)
                        .where.not(city: nil).where.not(city: '')
                        .order('1')
                        .pluck('DISTINCT(places.city)')
    end
  end
end
