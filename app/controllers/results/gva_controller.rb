class Results::GvaController < ApplicationController
  before_filter :campaign, except: :index

  before_filter :authorize_actions

  def index
    @campaigns = current_company.campaigns.accessible_by_user(current_company_user).order('name ASC')
  end

  def report
    authorize_actions
    @events_scope = filter_events_scope
    @group_header_data = {}
    goals = if area
      area.goals.in(campaign)
    elsif place
      place.goals.in(campaign)
    elsif company_user
      company_user.goals.in(campaign)
    elsif team
      team.goals.in(campaign)
    else
      campaign.goals.base
    end
    @group_header_data = kpis_headers_data(campaign) if params[:group_by] == 'campaign'
    goals = goals.where('goals.value is not null and goals.value <> 0')
    goals_activities = goals.joins(:activity_type).where(activity_type_id: campaign.activity_types.active).includes(:activity_type)
    goals_kpis = goals.joins(:kpi).where(kpi_id: campaign.active_kpis).includes(:kpi)
    @goals = (goals_kpis + goals_activities).sort_by{|g| g.kpi_id.present? ? g.kpi.name : g.activity_type.name }
  end

  def report_groups
    @goalables =  if params[:group_by] == 'place'
      campaign.children_goals.for_areas_and_places
    else
      campaign.children_goals.for_users_and_teams
    end.select('goalable_id, goalable_type').group('goalable_id, goalable_type').map(&:goalable).sort_by(&:name)

    @group_header_data = kpis_headers_data(@goalables)

    render layout: false
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

    def company_user
      @company_user ||= current_company.company_users.find(params[:item_id]) if params[:item_type].present? && params[:item_type] == 'CompanyUser'
    end

    def team
      @team ||= current_company.teams.find(params[:item_id]) if params[:item_type].present? && params[:item_type] == 'Team'
    end

    def authorize_actions
      authorize! :gva_report, Campaign
    end

    def filter_events_scope
      scope = Event.active.accessible_by_user(current_company_user).by_campaigns(campaign.id)
      scope = scope.in_areas([area]) unless area.nil?
      scope = scope.in_places([place]) unless place.nil?
      scope = scope.with_user_in_team(company_user) unless company_user.nil?
      scope = scope.with_team(team) unless team.nil?
      scope
    end


    def kpis_headers_data(goalables)
      if goalables.is_a?(Campaign)
        goals = Hash[campaign.goals.base.with_value.where(kpi_id: [Kpi.events.id, Kpi.promo_hours.id, Kpi.expenses.id, Kpi.samples.id]).map do |g|
          ["#{g.goalable_type}#{g.goalable_id}#{g.kpi_id}", g]
        end]
        goalables = [goalables]
      else
        goals = Hash[campaign.children_goals.with_value.where(kpi_id: [Kpi.events.id, Kpi.promo_hours.id, Kpi.expenses.id, Kpi.samples.id]).where('goalable_type || goalable_id in (?)', goalables.map{|g| "#{g.class.name}#{g.id}"}).map do |g|
          ["#{g.goalable_type}#{g.goalable_id}#{g.kpi_id}", g]
        end]
      end

      goal_keys = goals.keys
      queries = goalables.map do |goalable|
        events_scope = campaign.events.active.approved.select("ARRAY['#{goalable.id}', '#{goalable.class.name}'], '{KPI_NAME}', {KPI_AGGR}").reorder(nil)
        query = if goalable.is_a?(Area)
          events_scope.in_areas([goalable])
        elsif goalable.is_a?(Place)
          events_scope.in_places([goalable])
        elsif goalable.is_a?(CompanyUser)
          events_scope.with_user_in_team(goalable)
        elsif goalable.is_a?(Team)
          events_scope.with_team(goalable)
        else
          events_scope
        end
        [
          goal_keys.include?("#{goalable.class.name}#{goalable.id}#{Kpi.promo_hours.id}") ? query.to_sql.gsub('{KPI_NAME}', 'PROMO HOURS').gsub('{KPI_AGGR}', 'SUM(events.promo_hours)') : nil,
          goal_keys.include?("#{goalable.class.name}#{goalable.id}#{Kpi.events.id}") ? query.to_sql.gsub('{KPI_NAME}', 'EVENTS').gsub('{KPI_AGGR}', 'COUNT(events.id)') : nil,
          goal_keys.include?("#{goalable.class.name}#{goalable.id}#{Kpi.samples.id}") ? query.joins(:results).where(event_results: {kpi_id: Kpi.samples.id}).to_sql.gsub('{KPI_NAME}', 'SAMPLES').gsub('{KPI_AGGR}', 'SUM(event_results.scalar_value)') : nil,
          goal_keys.include?("#{goalable.class.name}#{goalable.id}#{Kpi.expenses.id}") ? query.joins(:event_expenses).to_sql.gsub('{KPI_NAME}', 'EXPENSES').gsub('{KPI_AGGR}', 'SUM(event_expenses.amount)') : nil
        ].compact
      end.flatten

      if queries.any?
        Hash[ActiveRecord::Base.connection.select_all("
          SELECT keys[1] as id, keys[2] as type, promo_hours, events, samples, expenses FROM crosstab('#{queries.join(' UNION ALL ').gsub('\'','\'\'')} ORDER by 1',
            'SELECT unnest(ARRAY[''PROMO HOURS'', ''EVENTS'', ''SAMPLES'', ''EXPENSES''])') AS ct(keys varchar[], promo_hours numeric, events numeric, samples numeric, expenses numeric)").map do |r|

          r['events'] = if goals["#{r['type']}#{r['id']}#{Kpi.events.id}"].present?
            r['events'].to_i * 100 / goals["#{r['type']}#{r['id']}#{Kpi.events.id}"].value
          else
            nil
          end

          r['promo_hours'] = if goals["#{r['type']}#{r['id']}#{Kpi.promo_hours.id}"].present?
            r['promo_hours'].to_i * 100 / goals["#{r['type']}#{r['id']}#{Kpi.promo_hours.id}"].value
          else
            nil
          end

          r['samples'] = if goals["#{r['type']}#{r['id']}#{Kpi.samples.id}"].present?
            r['samples'].to_i * 100 / goals["#{r['type']}#{r['id']}#{Kpi.samples.id}"].value
          else
            nil
          end

          r['expenses'] = if goals["#{r['type']}#{r['id']}#{Kpi.expenses.id}"].present?
            r['expenses'].to_i * 100 / goals["#{r['type']}#{r['id']}#{Kpi.expenses.id}"].value
          else
            nil
          end

          ["#{r['type']}#{r['id']}", r]
        end]
      else
        {}
      end
    end
end