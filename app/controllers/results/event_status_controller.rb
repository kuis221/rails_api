class Results::EventStatusController < ApplicationController
  before_filter :campaign, except: :index
  before_filter :authorize_actions

  def index
    @campaigns = current_company.campaigns.accessible_by_user(current_company_user).order('name ASC')
  end

  def report
    authorize_actions
  end

  private
    def campaign
      @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
    end

    def authorize_actions
      authorize! :event_status, Campaign
    end
end