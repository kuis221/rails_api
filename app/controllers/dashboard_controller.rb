class DashboardController < ApplicationController
  before_action :set_variables

  def index
  end

  def module
    render partial: "dashboard/modules/#{params[:module]}", layout: false
  end

  private
    def set_variables
      @campaign_overview_months = 6
    end
end
