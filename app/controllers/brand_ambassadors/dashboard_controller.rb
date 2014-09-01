class BrandAmbassadors::DashboardController < ApplicationController
  def index
    authorize! :access, :brand_ambassadors
    @visits = current_company.brand_ambassadors_visits
    @folder = current_company
  end
end
