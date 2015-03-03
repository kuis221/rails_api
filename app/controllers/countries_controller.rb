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
      render json: Neighborhood.where(state: state)
                        .order('1')
                        .pluck('DISTINCT(neighborhoods.city)')
    end
  end
end
