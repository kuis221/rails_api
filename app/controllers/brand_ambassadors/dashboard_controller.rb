class BrandAmbassadors::DashboardController < ApplicationController
  respond_to :js, only: [:index]
  respond_to :json, only: [:calendar]

  def index
    authorize! :access, :brand_ambassadors
    @visits = current_company.brand_ambassadors_visits
    @folder = current_company
  end
end
