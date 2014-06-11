class Results::GvaController < InheritedResources::Base
  respond_to :xls, only: :index

  before_filter :campaign, except: :index
  before_filter :authorize_actions

  helper_method :return_path

  def index
    if request.format.xls?
      @export = ListExport.create({controller: self.class.name, params: params, export_format: 'xls', company_user: current_company_user}, without_protection: true)
      if @export.new?
        @export.queue!
      end
      render action: :new_export, formats: [:js]
    end
  end

  def report
    set_report_scopes_for(area || place || company_user || team || campaign)
  end

  def report_groups
    @goalables = goalables_by_type

    @group_header_data = kpis_headers_data(@goalables)

    render layout: false
  end

  def export_list(export)
    @goalables_data = goalables_by_type.map do |goalable|
      set_report_scopes_for(goalable)
      {name: goalable.name , event_goal: view_context.each_events_goal}
    end

    Slim::Engine.with_options(pretty: true, sort_attrs: false, streaming: false) do
      render_to_string :index, handlers: [:slim], formats: [:xls], layout: false
    end
  end

  def export_file_name
    "#{controller_name.underscore.downcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
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
      if params[:report] && params[:report][:campaign_id]
        authorize! :gva_report_campaign, campaign
      else
        authorize! :gva_report, Campaign
      end
    end

    def filter_events_scope
      scope = Event.active.accessible_by_user(current_company_user).by_campaigns(campaign.id)
      scope = scope.in_areas([area]) unless area.nil?
      scope = scope.in_places([place]) unless place.nil?
      scope = scope.with_user_in_team(company_user) unless company_user.nil?
      scope = scope.with_team(team) unless team.nil?
      scope
    end

    def goalables_by_type
      if params[:group_by] == 'campaign'
        campaign.goals
      elsif params[:group_by] == 'place'
        campaign.children_goals.for_areas_and_places(campaign.area_ids, campaign.place_ids)
      else
        campaign.children_goals.for_users_and_teams
      end.select('goalable_id, goalable_type').where('value IS NOT NULL').includes(:goalable).group('goalable_id, goalable_type').map(&:goalable).sort_by(&:name)
    end

    def set_report_scopes_for(goalable)
      if params[:format] == 'xls' && (params[:group_by] == 'place' || params[:group_by] == 'staff')
        @area, @place, @company_user, @team = nil, nil, nil, nil
        params.merge!(item_type: goalable.class.name, item_id: goalable.id)
      end
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

      goals = goals.where('goals.value is not null and goals.value <> 0')
      goals_activities = goals.joins(:activity_type).where(activity_type_id: campaign.activity_types.active).includes(:activity_type)
      goals_kpis = goals.joins(:kpi).where(kpi_id: campaign.active_kpis).includes(:kpi)
      # Following KPIs should be displayed in this specific order at the beginning. Rest of KPIs and Activity Types should be next in the list ordered by name
      promotables = ['Events', 'Promo Hours', 'Expenses', 'Samples', 'Interactions', 'Impressions']
      @goals = (goals_kpis + goals_activities).sort_by{|g| g.kpi_id.present? ? (promotables.index(g.kpi.name) || ('A'+g.kpi.name)).to_s : g.activity_type.name }
    end

    def kpis_headers_data(goalables)
      if goalables.is_a?(Campaign)
        goals = Hash[campaign.goals.base.with_value.where(kpi_id: [Kpi.events.id, Kpi.promo_hours.id, Kpi.expenses.id, Kpi.samples.id]).map do |g|
          ["#{g.goalable_type}_#{g.goalable_id}_#{g.kpi_id}", g]
        end]
        goalables = [goalables]
      else
        goals = Hash[campaign.children_goals.with_value.where(kpi_id: [Kpi.events.id, Kpi.promo_hours.id, Kpi.expenses.id, Kpi.samples.id]).where('goalable_type || goalable_id in (?)', goalables.map{|g| "#{g.class.name}#{g.id}"}).map do |g|
          ["#{g.goalable_type}_#{g.goalable_id}_#{g.kpi_id}", g]
        end]
      end

      goal_keys = goals.keys
      items = {}
      goalables.each do |goalable|
        ['promo_hours', 'events', 'samples', 'expenses'].each do |kpi|
          items[goalable.class.name] ||= {}
          items[goalable.class.name][kpi] ||= []
          items[goalable.class.name][kpi].push goalable if goal_keys.include?("#{goalable.class.name}_#{goalable.id}_#{Kpi.send(kpi).id}")
        end
      end

      queries = items.map do |goalable_type, goaleables_ids|
        ['promo_hours', 'events', 'samples', 'expenses'].map do |kpi|
          events_scope = campaign.events.active.where(aasm_state: ['approved', 'rejected', 'submitted']).group('1').reorder(nil)
          query = if goaleables_ids[kpi].any?
            if goalable_type == 'Area'
              events_scope.in_areas(goaleables_ids[kpi]).select("ARRAY[areas_places.area_id::varchar, '#{goalable_type}'], '{KPI_NAME}', {KPI_AGGR}")
            elsif goalable_type == 'Place'
              events_scope.in_places(goaleables_ids[kpi]).select("ARRAY[places.id::varchar, '#{goalable_type}'], '{KPI_NAME}', {KPI_AGGR}")
            elsif goalable_type == 'CompanyUser'
              events_scope.with_user_in_team(goaleables_ids[kpi]).select("ARRAY[memberships.company_user_id::varchar, '#{goalable_type}'], '{KPI_NAME}', {KPI_AGGR}")
            elsif goalable_type == 'Team'
              events_scope.with_team(goaleables_ids[kpi]).select("ARRAY[teams.id::varchar, '#{goalable_type}'], '{KPI_NAME}', {KPI_AGGR}")
            else
              events_scope.select("ARRAY[events.campaign_id::varchar, 'Campaign'], '{KPI_NAME}', {KPI_AGGR}")
            end
          end

          if query
            if kpi == 'promo_hours'
              goaleables_ids['promo_hours'].any? ? query.to_sql.gsub('{KPI_NAME}', 'PROMO HOURS').gsub('{KPI_AGGR}', 'SUM(events.promo_hours)') : nil
            elsif kpi == 'events'
              goaleables_ids['events'].any? ? query.to_sql.gsub('{KPI_NAME}', 'EVENTS').gsub('{KPI_AGGR}', 'COUNT(events.id)') : nil
            elsif kpi == 'samples'
              goaleables_ids['samples'].any? ? query.joins(:results).where(event_results: {kpi_id: Kpi.samples.id}).to_sql.gsub('{KPI_NAME}', 'SAMPLES').gsub('{KPI_AGGR}', 'SUM(event_results.scalar_value)') : nil
            elsif kpi == 'expenses'
              goaleables_ids['expenses'].any? ? query.joins(:event_expenses).to_sql.gsub('{KPI_NAME}', 'EXPENSES').gsub('{KPI_AGGR}', 'SUM(event_expenses.amount)') : nil
            end
          end
        end
      end.flatten.compact

      if queries.any?
        Hash[ActiveRecord::Base.connection.select_all("
          SELECT keys[1] as id, keys[2] as type, promo_hours, events, samples, expenses FROM crosstab('#{queries.join(' UNION ALL ').gsub('\'','\'\'')} ORDER by 1',
            'SELECT unnest(ARRAY[''PROMO HOURS'', ''EVENTS'', ''SAMPLES'', ''EXPENSES''])') AS ct(keys varchar[], promo_hours numeric, events numeric, samples numeric, expenses numeric)").map do |r|

          r['events'] = if goals["#{r['type']}_#{r['id']}_#{Kpi.events.id}"].present?
            r['events'].to_f * 100 / goals["#{r['type']}_#{r['id']}_#{Kpi.events.id}"].value
          else
            nil
          end

          r['promo_hours'] = if goals["#{r['type']}_#{r['id']}_#{Kpi.promo_hours.id}"].present?
            r['promo_hours'].to_f * 100 / goals["#{r['type']}_#{r['id']}_#{Kpi.promo_hours.id}"].value
          else
            nil
          end

          r['samples'] = if goals["#{r['type']}_#{r['id']}_#{Kpi.samples.id}"].present?
            r['samples'].to_f * 100 / goals["#{r['type']}_#{r['id']}_#{Kpi.samples.id}"].value
          else
            nil
          end

          r['expenses'] = if goals["#{r['type']}_#{r['id']}_#{Kpi.expenses.id}"].present?
            r['expenses'].to_f * 100 / goals["#{r['type']}_#{r['id']}_#{Kpi.expenses.id}"].value
          else
            nil
          end

          ["#{r['type']}#{r['id']}", r]
        end]
      else
        {}
      end
    end

    def return_path
      results_reports_path
    end
end