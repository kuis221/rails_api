module DashboardHelper
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

  def campaign_promo_hours_chart(c)
    today_bar_indicator = ''.html_safe
    if c['today_percentage']
      color_class = if c['today_percentage'] < c['executed_percentage']
        'green'
      elsif c['today_percentage'] < c['executed_percentage']+c['scheduled_percentage']
        'blue'
      end
      today_bar_indicator = content_tag(:div, '', class: "today-line-indicator #{color_class}", style: "left: #{c['today_percentage'] - 0.5}%")
    end
    content_tag(:div, class: 'chart-bar') do
      today_bar_indicator +
      content_tag(:div, class: 'progress') do
        content_tag(:div, content_tag(:div, number_with_precision(c['executed'], strip_insignificant_zeros: true, delimiter: ','), class: 'bar-label executed-label'), class: 'bar bar-executed', style: "width: #{[100, c['executed_percentage']].min}%;") +
        content_tag(:div, content_tag(:div, number_with_precision(c['scheduled'], strip_insignificant_zeros: true, delimiter: ','), class: 'bar-label scheduled-label'), class: 'bar bar-scheduled', style: "width: #{c['scheduled_percentage']}%;") +
        content_tag(:div, '', class: 'bar bar-remaining', style: "width: #{c['remaining_percentage']}%;")
      end +
      content_tag(:div, content_tag(:div, "<b>#{number_with_precision(c['goal'], strip_insignificant_zeros: true, delimiter: ',')}</b> GOAL".html_safe), class: 'goal-label')+
      content_tag(:div, class: 'remaining-label' + (c['remaining'] < 0 ? ' over-goal' : '')) do
        content_tag(:b, number_with_precision(c['remaining'].abs, strip_insignificant_zeros: true, delimiter: ',')) +
        content_tag(:span, c['kpi'], class: 'kpi-name') +
        content_tag(:span, (c['remaining'] < 0 ? 'OVER' : 'REMAINING' ) )
      end
    end
  end

  def gva_chart(g)
    today_bar_indicator = ''.html_safe
    if g[:today_percentage]
      today = number_with_precision(g[:today], strip_insignificant_zeros: true, delimiter: ',')
      today_bar_indicator = content_tag(:div, '', class: "today-line-indicator has-tooltip", title: "<span class=today-label>TODAY:</span> #{today}", data: {delay: 0}, style: "left: #{g[:today_percentage] - 0.5}%")
    end
    value_prefix = g[:goal].kpi.present? && g[:goal].kpi.currency? ? '$' : ''
    goal = number_with_precision(g[:goal].value, strip_insignificant_zeros: true, delimiter: ',')
    actual = number_with_precision(g[:total_count], strip_insignificant_zeros: true, delimiter: ',')
    actual_percentage = g[:completed_percentage]
    submitted = number_with_precision(g[:submitted], strip_insignificant_zeros: true, delimiter: ',')
    submitted_percentage = g[:submitted_percentage]
    rejected = number_with_precision(g[:rejected], strip_insignificant_zeros: true, delimiter: ',')
    rejected_percentage = g[:rejected_percentage]
    total =  number_with_precision(g[:total_count]+g[:submitted]+g[:rejected], strip_insignificant_zeros: true, delimiter: ',')
    bar_tooltip = content_tag(:div, content_tag(:span, 'APPROVED:') + value_prefix + actual, class: 'executed-label') +
      content_tag(:div, content_tag(:span, 'SUBMITTED:') + value_prefix + submitted, class: 'submitted-label') +
      content_tag(:div, content_tag(:span, 'REJECTED:') + value_prefix + rejected, class: 'rejected-label')

    content_tag(:div, class: 'chart-bar gva') do
      today_bar_indicator +
      content_tag(:div, class: 'progress gva has-tooltip', title: bar_tooltip.gsub('"', ''), data: {delay: 0}) do
        content_tag(:div, '', class: 'bar bar-executed', style: "width: #{[100, g[:completed_percentage]].min}%;") +
        content_tag(:div, '', class: 'bar bar-scheduled', style: "width: #{[[100 - actual_percentage, submitted_percentage].min, 0].max}%;") +
        content_tag(:div, '', class: 'bar bar-rejected', style: "width: #{[[100 - actual_percentage - submitted_percentage, rejected_percentage].min, 0].max}%;")
      end +
      content_tag(:div, class: 'progress-label percentage') do
        content_tag(:b, "#{(actual_percentage+submitted_percentage+rejected_percentage).truncate}<span class=\"normal-text\">%</span>".html_safe, class: 'percentage') +
        content_tag(:div, "<b>#{value_prefix}#{total}</b> <span class=total-of>OF</span> <b>#{value_prefix}#{goal}</b> GOAL".html_safe, class: 'progress-numbers')
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
          (event.week_start.to_i..event.week_end.to_i).each do |week|
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