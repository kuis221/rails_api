class CountriesController < ApplicationController
  skip_before_filter :authenticate_user!

  def states
    @country = Country.new(params[:country])
  end
end
