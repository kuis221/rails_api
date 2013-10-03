class Analysis::CampaignsReportController < ApplicationController
  before_filter :campaign, except: :index

  before_filter :authorize_actions

  def index
    @campaigns = current_company.campaigns.order('name ASC')
  end

  def report
    authorize! :show, campaign
    @events_scope = Event.scoped_by_campaign_id(campaign).where(aasm_state: 'approved')
    @goals = campaign.goals.base.joins(:kpi).where(kpi_id: campaign.active_kpis).includes(:kpi).all
  end

  private
    def campaign
      @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
    end

    def authorize_actions
      authorize! :show_analysis, Campaing
    end
end