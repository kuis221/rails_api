module DashboardHelper
  def dashboard_demographics_graph_data
    @demographics_graph_data ||= Hash.new.tap do |data|
      results_scope = EventResult.scoped_by_company_id(current_company)
      [:age, :gender, :ethnicity].each do |kpi|
        results = results_scope.send(kpi).select('event_results.kpis_segment_id, sum(event_results.scalar_value) AS segment_sum, avg(event_results.scalar_value) AS segment_avg').group('event_results.kpis_segment_id')
        segments = Kpi.send(kpi).kpis_segments
        data[kpi] = Hash[segments.map{|s| [s.text, results.detect{|r| r.kpis_segment_id == s.id}.try(:segment_avg).try(:to_f) || 0]}]
      end
    end
  end


  def recent_photos_list
    AttachedAsset.do_search({company_id: current_company.id, asset_type: 'photo', per_page: 12, sorting: :created_at, sorting_dir: :desc }).results
  end

  def dashboard_kpis_trends_data
    @kpis_trends_data ||= Hash.new.tap do |data|
      result = EventData.select('
          count(event_data.id) as events_count,
          sum(event_data.impressions) as impressions,
          sum(event_data.interactions) as interactions,
          sum(event_data.samples) as sampled,
          sum(event_data.spent) as spent
      ').scoped_by_company_id(current_company).first
      data[:events] = result.events_count.to_i
      data[:impressions] = result.impressions.to_i
      data[:interactions] = result.interactions.to_i
      data[:spent] = result.spent.to_f

      if result.events_count.to_i > 0
        data[:impressions_event] = result.impressions.to_i/result.events_count.to_i
        data[:interactions_event] = result.interactions.to_i/result.events_count.to_i
        data[:sampled_event] = result.sampled.to_i/result.events_count.to_i
      end

      if result.impressions.to_i > 0
        data[:cost_impression] = result.spent.to_f / result.impressions.to_i
        data[:cost_interaction] = result.spent.to_f / result.interactions.to_i
        data[:cost_sample] = result.spent.to_f / result.sampled.to_i
      end
    end
  end

  def upcomming_events_list
    @upcomming_events = current_company.events.includes([:campaign, :place]).active.upcomming.limit(5)
  end

  def my_incomplete_tasks
    Task.includes(event: :campaign).active.incomplete.where(company_user_id: current_company_user).limit(5)
  end

  def team_incomplete_tasks
    Task.includes(event: :campaign).active.incomplete.where(company_user_id: current_company_user.find_users_in_my_teams).limit(5)
  end

  def top5_venues
    Venue.scoped_by_company_id(current_company).where('score is not null').includes(:place).order('venues.score DESC').limit(5)
  end

  def bottom5_venues
    Venue.scoped_by_company_id(current_company).where('score is not null').includes(:place).order('venues.score ASC').limit(5)
  end

  def kpi_trends_stats(kpi)
    @kpi_trends_totals ||= {}
    @kpi_trends_totals[kpi.id] ||= Hash.new.tap do |data|
      campaigns_scope = current_company.campaigns.with_goals_for(kpi)
      campaign_ids =  campaigns_scope.select('campaigns.id').map(&:id)
      data[:goal] = campaigns_scope.sum('goals.value').to_i
      data[:completed] = compute_completed_for(kpi, campaign_ids)
      data[:remaining] = 0
      data[:remaining] = [data[:goal] - data[:completed], 0].max if data[:completed]
      data[:completed_percentage] = 0
      data[:remaining_percentage] = 0
      data[:today_percentage] =  0

      if data[:goal] > 0
        data[:completed_percentage] = (data[:completed] * 100 / data[:goal]).round
        data[:remaining_percentage] = [100 - data[:completed_percentage], 0].max
        data[:today_percentage] =  0

        dates_result = campaigns_scope.select('min(first_event_at) as first_event_at, max(last_event_at) as last_event_at').first
        if dates_result.first_event_at && dates_result.last_event_at
          total_days = ((dates_result.last_event_at  - dates_result.first_event_at).to_i / 86400).round
          today_days = ((Time.now  - dates_result.first_event_at).to_i / 86400).round
          data[:today_percentage] = today_days * 100 / total_days if total_days > 0
        end
      end
    end
  end

  def kpi_trend_chart_bar(kpi)
    totals = kpi_trends_stats(kpi)
    content_tag(:div, class: 'chart-bar') do
      content_tag(:div, '', class: 'today-line-indicator', style: "left: #{totals[:today_percentage]}%") +
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


  private
    def compute_completed_for(kpi, campaign_ids)
      case kpi
      when Kpi.events
        kpis_completed_totals(campaign_ids)['events_count']
      when Kpi.promo_hours
        kpis_completed_totals(campaign_ids)['promo_hours']
      when Kpi.impressions
        kpis_completed_totals(campaign_ids)['impressions']
      when Kpi.interactions
        kpis_completed_totals(campaign_ids)['interactions']
      when Kpi.samples
        kpis_completed_totals(campaign_ids)['samples']
      when Kpi.expenses
        kpis_completed_totals(campaign_ids)['spent']
      else
        0
      end
    end

    def kpis_completed_totals(campaign_ids)
      @kpis_completed_totals ||= Hash.new.tap do |totals|
        search = Event.do_search({company_id: current_company.id, with_event_data_only: true, campaign: campaign_ids, event_data_stats: true})
        totals['events_count'] = search.total
        totals['promo_hours'] = search.stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
        totals['impressions'] = search.stat_response['stats_fields']["impressions_es"]['sum'] rescue 0
        totals['interactions'] = search.stat_response['stats_fields']["interactions_es"]['sum'] rescue 0
        totals['samples'] = search.stat_response['stats_fields']["samples_es"]['sum'] rescue 0
        totals['spent'] = search.stat_response['stats_fields']["spent_es"]['sum'] rescue 0
      end
    end
end