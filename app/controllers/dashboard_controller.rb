class DashboardController < ApplicationController
  def index
  end

  def module
    render partial: "dashboard/modules/#{params[:module]}", layout: false
  end
end
