class Analysis::CampaignsReportController < ApplicationController
  before_filter :campaign, only: :report
  authorize_resource :campaign, only: :report

  def index
    @campaigns = current_company.campaigns.accessible_by(current_ability)
  end

  def report
  end

  private
    def campaign
      @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
    end
end