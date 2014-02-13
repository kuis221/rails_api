module DashboardHelper
  def dashboard_demographics_graph_data
    @demographics_graph_data ||= Hash.new.tap do |data|
      results_scope = EventResult.for_approved_events.scoped_by_company_id(current_company).scoped(event_data_scope_conditions)
      [:age, :gender, :ethnicity].each do |kpi|
        if segments = Kpi.send(kpi).try(:kpis_segments)
          results = results_scope.send(kpi).where('kpis_segment_id in (?)', segments.map(&:id)).select('event_results.kpis_segment_id, sum(event_results.scalar_value) AS segment_sum, avg(event_results.scalar_value) AS segment_avg, count(event_results.id) as result_count').group('event_results.kpis_segment_id')
          totals = results.sum{|r|r.segment_sum.to_f}
          data[kpi] = Hash[segments.map do |s|
            [s.text, if r = results.detect{|r| r.kpis_segment_id == s.id}
              if totals > 0
                r.segment_sum.to_f * 100 / totals
              else
                0
              end
            else
              0
            end
            ]
          end]
        end
      end
    end
  end

  def recent_photos_list
    AttachedAsset.do_search({company_id: current_company.id, current_company_user: current_company_user, asset_type: 'photo', per_page: 12, sorting: :created_at, sorting_dir: :desc }).results
  end

  def upcoming_events_list
    Event.do_search({company_id: current_company.id, current_company_user: current_company_user, per_page: 5, sorting: :start_at, sorting_dir: :asc, start_date: Time.zone.now.strftime("%m/%d/%Y"), end_date: Time.zone.now + 10.years, event_status: ['Active']}).results
  end

  def my_incomplete_tasks
    Task.do_search({company_id: current_company.id, current_company_user: current_company_user, user: [current_company_user.id], task_status: ['Incomplete'], per_page: 5, sorting: :due_at, sorting_dir: :asc }).results
  end

  def team_incomplete_tasks
    Task.do_search({company_id: current_company.id, current_company_user: current_company_user, team_members: [current_company_user.id], not_assigned_to: [current_company_user.id], task_status: ['Incomplete'], per_page: 5, sorting: :due_at, sorting_dir: :asc }).results
  end

  def top5_venues
    Venue.do_search({company_id: current_company.id, current_company_user: current_company_user, per_page: 5, sorting: :venue_score, venue_score: {min: 0}, sorting_dir: :desc }).results
  end

  def bottom5_venues
    Venue.do_search({company_id: current_company.id, current_company_user: current_company_user, per_page: 5, sorting: :venue_score, venue_score: {min: 0}, sorting_dir: :asc }).results
  end

  def kpi_trends_stats(kpi)
    @kpi_trends_totals ||= {}
    @kpi_trends_totals[kpi.id] ||= Hash.new.tap do |data|
      campaigns_scope = current_company.campaigns.with_goals_for(kpi)
      campaigns_scope = campaigns_scope.where(id: current_company_user.accessible_campaign_ids) unless current_company_user.is_admin?
      campaign_ids =  campaigns_scope.select('campaigns.id').map(&:id)

      data[:goal] = campaigns_scope.sum('goals.value').to_i
      data[:completed] = get_totals_for_kpi(kpi, kpis_completed_totals(campaign_ids))
      data[:executed] = get_totals_for_kpi(kpi, kpis_executed_totals(campaign_ids))
      data[:remaining] = 0
      data[:remaining] = [data[:goal] - data[:completed], 0].max if data[:completed]
      data[:completed_percentage] = 0
      data[:remaining_percentage] = 0
      data[:today_percentage] =  0
      data[:executed_percentage] =  0

      if data[:goal] > 0
        data[:completed_percentage] = (data[:completed] * 100 / data[:goal]).round
        data[:remaining_percentage] = [100 - data[:completed_percentage], 0].max
        data[:executed_percentage] = (data[:executed] * 100 / data[:goal]).round

        # dates_result = campaigns_scope.select('min(first_event_at) as first_event_at, max(last_event_at) as last_event_at').first
        # if dates_result.first_event_at && dates_result.last_event_at
        #   total_days = ((dates_result.last_event_at  - dates_result.first_event_at).to_i / 86400).round
        #   today_days = ((Time.now  - dates_result.first_event_at).to_i / 86400).round
        #   data[:today_percentage] = today_days * 100 / total_days if total_days > 0
        # end

      end
    end
  end

  def kpi_trend_chart_bar(kpi)
    unless kpi.nil?
      totals = kpi_trends_stats(kpi)
      content_tag(:div, class: 'chart-bar') do
        content_tag(:div, '', class: 'today-line-indicator has-tooltip', 'data-toggle' => "tooltip", title: "#{kpi.currency? ? number_to_currency(totals[:executed]) : number_with_delimiter(totals[:executed])} executed", style: "left: #{totals[:executed_percentage]}%") +
        content_tag(:div, class: 'progress') do
          content_tag(:div, class: 'bar has-tooltip', 'data-toggle' => "tooltip", title: "#{kpi.currency? ? number_to_currency(totals[:completed]) : number_with_delimiter(totals[:completed])} completed", style: "width: #{[100, totals[:completed_percentage]].min}%;") do
            content_tag(:span, "#{totals[:completed_percentage]}%", class: :percentage)
          end +
          content_tag(:div, class: 'bar bar-remaining has-tooltip', 'data-toggle' => "tooltip", title: "#{kpi.currency? ? number_to_currency(totals[:remaining]) : number_with_delimiter(totals[:remaining])} remaining", style: "width: #{totals[:remaining_percentage]}%;") do
            content_tag(:span, "#{totals[:remaining_percentage]}%", class: :percentage)
          end
        end +
        content_tag(:span, kpi.currency? ? number_to_currency(totals[:goal]) : number_with_delimiter(totals[:goal]), class: :total)
      end
    end
  end


  def kpis_completed_totals(campaign_ids=[])
    @kpis_completed_totals ||= {}
    @kpis_completed_totals['c'+campaign_ids.join('-')] ||= Hash.new.tap do |totals|
      search = Event.do_search({company_id: current_company.id, current_company_user: current_company_user, campaign: campaign_ids, event_data_stats: true, status: ['Active'], event_status: ['Approved']})
      totals['events_count'] = search.total
      totals['promo_hours'] = search.stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
      totals['impressions'] = search.stat_response['stats_fields']["impressions_es"]['sum'] rescue 0
      totals['interactions'] = search.stat_response['stats_fields']["interactions_es"]['sum'] rescue 0
      totals['samples'] = search.stat_response['stats_fields']["samples_es"]['sum'] rescue 0
      totals['spent'] = search.stat_response['stats_fields']["spent_es"]['sum'] rescue 0

      if totals['events_count'] > 0
        totals['impressions_event'] = totals['impressions']/totals['events_count']
        totals['interactions_event'] = totals['interactions']/totals['events_count']
        totals['sampled_event'] = totals['samples']/totals['events_count']
      else
        totals['impressions_event'] = 0
        totals['interactions_event'] = 0
        totals['sampled_event'] = 0
      end

      if totals['impressions'] > 0
        totals['cost_impression'] = totals['spent'] / totals['impressions']
        totals['cost_interaction'] = totals['spent'] / totals['interactions']
        totals['cost_sample'] = totals['spent'] / totals['samples']
      else
        totals['cost_impression'] = 0
        totals['cost_interaction'] = 0
        totals['cost_sample'] = 0
      end
    end
  end

  def kpis_executed_totals(campaign_ids=[])
    @kpis_executed_totals ||= {}
    @kpis_executed_totals['c'+campaign_ids.join('-')] ||= Hash.new.tap do |totals|
      search = Event.do_search({company_id: current_company.id, current_company_user: current_company_user, campaign: campaign_ids, event_data_stats: true, status: ['Active'], start_date: '01/01/1900', end_date:  Time.zone.now.to_s(:slashes)})
      totals['events_count'] = search.total
      totals['promo_hours'] = search.stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
      totals['impressions'] = search.stat_response['stats_fields']["impressions_es"]['sum'] rescue 0
      totals['interactions'] = search.stat_response['stats_fields']["interactions_es"]['sum'] rescue 0
      totals['samples'] = search.stat_response['stats_fields']["samples_es"]['sum'] rescue 0
      totals['spent'] = search.stat_response['stats_fields']["spent_es"]['sum'] rescue 0

      if totals['events_count'] > 0
        totals['impressions_event'] = totals['impressions']/totals['events_count']
        totals['interactions_event'] = totals['interactions']/totals['events_count']
        totals['sampled_event'] = totals['samples']/totals['events_count']
      else
        totals['impressions_event'] = 0
        totals['interactions_event'] = 0
        totals['sampled_event'] = 0
      end

      if totals['impressions'] > 0
        totals['cost_impression'] = totals['spent'] / totals['impressions']
        totals['cost_interaction'] = totals['spent'] / totals['interactions']
        totals['cost_sample'] = totals['spent'] / totals['samples']
      else
        totals['cost_impression'] = 0
        totals['cost_interaction'] = 0
        totals['cost_sample'] = 0
      end
    end
  end

  def campaign_overview_data
    @campaign_overview_data ||= begin
      data = {}
      prefix = ''
      prefix = 'local_' if Company.current.present? && Company.current.timezone_support?
      start_date = Date.today.beginning_of_month
      start_date = start_date.next_week unless start_date.wday == 1
      start_week_number = start_date.strftime("%U").to_i+1
      Rails.logger.debug "\n\n\n\n"
      Event.active.between_dates(start_date.beginning_of_day, (Date.today.beginning_of_month+4.months).end_of_month.end_of_day).
            accessible_by_user(current_company_user).
            where(campaign_id: dashboard_accessible_campaigns.map(&:id)).
            group('1, 2, 3').
            select("events.campaign_id, EXTRACT(WEEK FROM #{prefix}start_at) as week_start, EXTRACT(WEEK FROM #{prefix}end_at) as week_end").
            each do |event|
          (event.week_start..event.week_end).each do |week|
            data[event.campaign_id] ||= {}
            data[event.campaign_id][week.to_i]=true if start_week_number <= week.to_i
          end
      end
      Rails.logger.debug "\n\n\n\n"
      data
    end
  end

  def dashboard_accessible_campaigns
    @dashboard_accessible_campaigns ||= current_company.campaigns.active.accessible_by_user(current_company_user).order(:name)
  end

  def campaing_cell_clasess(campaign, week)
    clasess = []
    week_number = week.strftime("%U").to_i+1
    clasess.push 'in-range' if campaign.has_date_range? && campaign.end_date > week && campaign.start_date < week.end_of_week
    if campaign_overview_data[campaign.id].present? && campaign_overview_data[campaign.id][week_number]
      clasess.push 'with-events'
      clasess.push 'first-in-series' unless campaign_overview_data[campaign.id][week_number-1].present? && campaign_overview_data[campaign.id][week_number-1]
      clasess.push 'last-in-series' unless campaign_overview_data[campaign.id][week_number+1]
    end
    clasess.join(' ')
  end

  def weeks_in_month(date)
    week = date.beginning_of_week+1.week
    weeks = []
    while week.month == date.month
      weeks.push week
      week += 1.week
    end
    weeks
  end

  private
    def get_totals_for_kpi(kpi, totals)
      case kpi
      when Kpi.events
        totals['events_count']
      when Kpi.promo_hours
        totals['promo_hours']
      when Kpi.impressions
        totals['impressions']
      when Kpi.interactions
        totals['interactions']
      when Kpi.samples
        totals['samples']
      when Kpi.expenses
        totals['spent']
      else
        0
      end
    end

    def event_data_scope_conditions
      conditions = {}
      conditions = {conditions: {events: events_scope_conditions}} unless current_company_user.is_admin?
    end

    def events_scope_conditions
      conditions = {}
      conditions = {campaign_id: current_company_user.accessible_campaign_ids} unless current_company_user.is_admin?
    end
end