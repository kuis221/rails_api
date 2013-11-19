class Results::GvaController < ApplicationController
  before_filter :campaign, except: :index

  before_filter :authorize_actions

  helper_method :event_status_stats_for_events, :event_status_stats_for_promo_hours

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

    # Returns an array of areas/places with the statistics by event status compared to the area or place's goals
    def event_status_stats_for_events
      search_params = {company_id: current_company.id, campaign: [campaign.id], status: ['Active'], current_company_user: current_company_user}
      stats = {}
      Goal.in(campaign).
        where('goals.value <> 0 and goals.value is not null').
        where('(goals.goalable_type=\'Area\' and goals.goalable_id in (?)) or (goals.goalable_type=\'Place\' and goals.goalable_id in (?))', campaign.area_ids, campaign.place_ids).
        where(kpi_id: Kpi.events.id).map do |goal|
          params = search_params
          params.merge!({area: goal.goalable.id}) if goal.goalable.is_a?(Area)
          params.merge!({place: [Base64.encode64(Place.location_for_index(goal.goalable))]}) if goal.goalable.is_a?(Place)
          search = Event.do_search(params, true)
          status_facets = search.facet(:status).rows
          submitted = status_facets.detect{|f| f.value == :submitted}.try(&:count) || 0
          executed  = status_facets.detect{|f| f.value == :executed}.try(&:count) || 0
          scheduled = search.total
          stats[goal.goalable.name] = {goal: goal, scheduled: scheduled, executed: executed, remaining: goal.value - executed}
      end
      stats
    end


    # Returns an array of areas/places with the statistics by event status compared to the area or place's goals
    def event_status_stats_for_promo_hours
      search_params = {company_id: current_company.id, campaign: [campaign.id], status: ['Active'], current_company_user: current_company_user, event_data_stats: true}
      stats = {}
      Goal.in(campaign).
        where('goals.value <> 0 and goals.value is not null').
        where('(goals.goalable_type=\'Area\' and goals.goalable_id in (?)) or (goals.goalable_type=\'Place\' and goals.goalable_id in (?))', campaign.area_ids, campaign.place_ids).
        where(kpi_id: Kpi.promo_hours.id).map do |goal|
          params = search_params
          params.merge!({area: goal.goalable.id}) if goal.goalable.is_a?(Area)
          params.merge!({place: [Base64.encode64(Place.location_for_index(goal.goalable))]})   if goal.goalable.is_a?(Place)
          search = Event.do_search(params, true)
          status_facets = search.facet(:status).rows
          submitted = Event.do_search(params.merge(event_status: [:submitted]), true).stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
          executed = Event.do_search(params.merge(event_status: [:executed]), true).stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
          scheduled = search.stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
          stats[goal.goalable.name] = {goal: goal, scheduled: scheduled, executed: executed, remaining: goal.value - executed}
      end
      stats
    end

    def filter_event_ids
      params = {company_id: current_company.id, campaign: [campaign.id], status: ['Active'], current_company_user: current_company_user, per_page: 100000}
      params.merge!({area: area.id}) unless area.nil?
      params.merge!({place: [Base64.encode64(Place.location_for_index(place))]}) unless place.nil?
      Event.do_search(params).hits.map(&:primary_key)
    end
end