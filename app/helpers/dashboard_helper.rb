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

  def recent_comments_list
    Comment.for_user_accessible_events(current_company_user).includes(commentable: [:campaign, :place]).order('comments.created_at DESC').limit(9)
  end

  def campaing_promo_hours_chart(c)
    remaining_percentage = 100-c['executed_percentage']-c['scheduled_percentage']
    today_bar_indicator = ''.html_safe
    if c['today_percentage']
      color_class = if c['today_percentage'] < c['executed_percentage']
        'green'
      elsif c['today_percentage'] < c['executed_percentage']+c['scheduled_percentage']
        'blue'
      end
      today_bar_indicator = content_tag(:div, '', class: "today-line-indicator #{color_class}", style: "left: #{c['today_percentage'] - 0.5}%")
    end
    one_line = (105-c['scheduled_percentage']) > 100
    content_tag(:div, class: 'chart-bar') do
      today_bar_indicator +
      content_tag(:div, '', class: 'bar-indicator executed-indicator', style: "left: #{c['executed_percentage']}%") +
      content_tag(:div, '', class: 'bar-indicator scheduled-indicator', style: "left: #{c['executed_percentage']+c['scheduled_percentage']}%; height: #{one_line ? 37: 23}px") +
      content_tag(:div, class: 'progress') do
        content_tag(:div, '', class: 'bar bar-executed', style: "width: #{[100, c['executed_percentage']].min}%;") +
        content_tag(:div, '', class: 'bar bar-scheduled', style: "width: #{c['scheduled_percentage']}%;") +
        content_tag(:div, '', class: 'bar bar-remaining', style: "width: #{c['remaining_percentage']}%;")
      end +
      content_tag(:div, content_tag(:div, "<b>#{number_with_precision(c['executed'], strip_insignificant_zeros: true)}</b>".html_safe), class: 'executed-label', style: "margin-left: #{c['executed_percentage']}%; margin-right: #{ one_line ? 50: 0}%") +
      content_tag(:div, content_tag(:div, "<b>#{number_with_precision(c['scheduled'], strip_insignificant_zeros: true)}</b>".html_safe), class: 'scheduled-label', style: "float: right; margin-right: #{101-c['scheduled_percentage']-c['executed_percentage']}%; margin-top:#{ one_line ? -11: 0}px") +
      content_tag(:div, content_tag(:div, "<b>#{number_with_precision(c['goal'], strip_insignificant_zeros: true)}</b> GOAL".html_safe), class: 'goal-label')+
      content_tag(:div, class: 'remaining-label') do
        content_tag(:b, number_with_precision(c['remaining'], strip_insignificant_zeros: true, delimiter: ',')) +
        content_tag(:span, c['kpi'], class: 'kpi-name') +
        content_tag(:span, 'REMAINING')
      end
    end
  end

  def gva_chart(g)
    goal = g[:goal].kpi.present? && g[:goal].kpi.currency? ? number_to_currency(g[:goal].value, precision: 2) : number_with_delimiter(g[:goal].value)
    actual = g[:goal].kpi.present? && g[:goal].kpi.currency? ? number_to_currency(g[:total_count], precision: 2) : number_with_delimiter(g[:total_count])
    pending_and_total = (g[:submitted] || 0) + g[:total_count]
    pending = g[:goal].kpi.present? && g[:goal].kpi.currency? ? number_to_currency(pending_and_total, precision: 2) : number_with_delimiter(pending_and_total.round(2))
    actual_percentage = g[:completed_percentage].round
    pending_percentage = (pending_and_total/g[:goal].value * 100).round
    content_tag(:div, class: 'chart-bar') do
      content_tag(:div, '', class: 'bar-indicator executed-indicator', style: "left: #{[100, actual_percentage].min}%") +
      content_tag(:div, '', class: 'bar-indicator scheduled-indicator', style: "left: #{[100, pending_percentage].min}%") +
      content_tag(:div, '', class: 'bar-indicator goal-indicator', style: "left: 100%") +
      content_tag(:div, class: 'progress') do
        content_tag(:div, '', class: 'bar bar-executed', style: "width: #{[100, actual_percentage].min}%;") +
        content_tag(:div, '', class: 'bar bar-scheduled', style: "width: #{pending_percentage - actual_percentage}%;")
      end +
      content_tag(:div, content_tag(:div, "<b>#{actual}</b> ACTUAL".html_safe), class: 'executed-label', style: "margin-left: #{[100, actual_percentage].min}%") +
      content_tag(:div, content_tag(:div, "<b>#{pending}</b> PENDING".html_safe), class: 'scheduled-label', style: "float: right; margin-right: #{100 - pending_percentage}%") +
      content_tag(:div, content_tag(:div, "<b>#{goal}</b> GOAL".html_safe), class: 'goal-label') +
      content_tag(:div, class: 'remaining-label percentage') do
        content_tag(:b, "#{actual_percentage}%", class: 'percentage') +
        content_tag(:span, "COMPLETE", class: 'percentage') +
        content_tag(:b, "#{pending_percentage}%", class: 'percentage') +
        content_tag(:span, 'PENDING', class: 'percentage')
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
      Event.active.between_dates(start_date.beginning_of_day, (Date.today.beginning_of_month+@campaign_overview_months.months).end_of_month.end_of_day).
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
      data
    end
  end

  def dashboard_accessible_campaigns
    @dashboard_accessible_campaigns ||= current_company.campaigns.active.accessible_by_user(current_company_user).order(:name)
  end

  # Returns a list of campaigns accessible for the current with promo hours goal
  def dashboard_promo_hours_graph_data
    current_company.campaigns.active.accessible_by_user(current_company_user).promo_hours_graph_data
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