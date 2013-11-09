class Results::GvaController < ApplicationController
  before_filter :campaign, except: :index

  before_filter :authorize_actions

  def index
    @campaigns = current_company.campaigns.accessible_by_user(current_company_user).order('name ASC')
  end

  def report
    authorize! :report, campaign

    @events_scope = Event.where(id: filter_event_ids)
    if area
      @goals = area.goals.in(campaign)
    elsif place
      @goals = place.goals.in(campaign)
    else
      @goals = campaign.goals.base
    end
    @goals = @goals.joins(:kpi).where(kpi_id: campaign.active_kpis).where('goals.value is not null').includes(:kpi).all
  end

  private
    def campaign
      @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
    end

    def area
      @area ||= current_company.areas.find(params[:item_id]) if params[:item_type].present? && params[:item_type] == 'Area'
    end

    def place
      @place ||= Place.find(params[:item_id]) if params[:item_type].present? && params[:item_type] == 'Place'
    end

    def authorize_actions
      authorize! :show_analysis, Campaign
    end

    def filter_event_ids
      params = {company_id: current_company.id, campaign: [campaign.id], status: ['Active'], current_company_user: current_company_user, per_page: 100000}
      params.merge!({area: area.id}) unless area.nil?
      params.merge!({place: [Base64.encode64(Place.location_for_index(place))]}) unless place.nil?
      p params.inspect
      Event.do_search(params).hits.map(&:primary_key)
    end
end