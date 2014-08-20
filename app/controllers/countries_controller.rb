class CountriesController < ApplicationController
  skip_before_action :authenticate_user!

  def states
    @country = Country.new(params[:country]) if params[:country].present?
  end
end
