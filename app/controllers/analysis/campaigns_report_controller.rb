class Analysis::CampaignsReportController < ApplicationController
  before_filter :campaign, except: :index
  authorize_resource :campaign, except: :index

  def index
    @campaigns = current_company.campaigns.order('name ASC')
  end

  def report
    @events_scope = Event.scoped_by_campaign_id(campaign).where(aasm_state: 'approved')
    @goals = campaign.goals.joins(:kpi).where(kpi_id: campaign.active_kpis).includes(:kpi).all
  end

  private
    def campaign
      @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
    end
end