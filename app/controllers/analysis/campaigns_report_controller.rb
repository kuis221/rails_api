class Analysis::CampaignsReportController < ApplicationController
  before_filter :campaign, except: :index

  before_filter :authorize_actions

  def index
    @campaigns = current_company.campaigns.accessible_by_user(current_company_user).order('name ASC')
  end

  def report
    authorize! :report, campaign
    @events_scope = Event.where(campaign_id: campaign, aasm_state: 'approved')
    @goals = campaign.goals.base.joins(:kpi).where(kpi_id: campaign.active_kpis).where('goals.value is not null').includes(:kpi).all
  end

  private
    def campaign
      @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
    end

    def authorize_actions
      authorize! :show_analysis, Campaign
    end
end