include SurveySeriesHelper

module Analysis
	module CampaignsReportHelper
    #
    # ___________.__                _____                          __
    # \__    ___/|  |__   ____     /     \   ____   ____   _______/  |_  ___________
    #   |    |   |  |  \_/ __ \   /  \ /  \ /  _ \ /    \ /  ___/\   __\/ __ \_  __ \
    #   |    |   |   Y  \  ___/  /    Y    (  <_> )   |  \\___ \  |  | \  ___/|  | \/
    #   |____|   |___|  /\___  > \____|__  /\____/|___|  /____  > |__|  \___  >__|
    #                 \/     \/          \/            \/     \/            \/
    #  This methods fetchs all the data required to generate the reports for the campaing
    #  The results looks something like this:
    #
    def campaigns_events_data
      @campaign_data ||= begin

        events_goal = @campaign.goals.for_kpis([Kpi.events]).first.try(:value) || 0
        promo_hours_goal = @campaign.goals.for_kpis([Kpi.promo_hours]).first.try(:value) || 0

        data = {
            'scheduled_events' => 0,
            'remaining_events' => 0,
            'approved_events' => 0,
            'expected_events' => 0,
            'expected_events_today' => 0,
            'events_percentage' => 0,
            'events_percentage_today' => 0,
            'events_goal' => events_goal,

            'scheduled_promo_hours' => 0,
            'approved_promo_hours' => 0,
            'remaining_promo_hours' => 0,
            'expected_promo_hours' => 0,
            'expected_promo_hours_today' => 0,
            'promo_hours_percentage' => 0,
            'promo_hours_percentage_today' => 0,
            'promo_hours_goal' => promo_hours_goal,

            'approved_events_week_avg' => 0,
            'approved_promo_hours_week_avg' => 0,
            'approved_events_this_week' => nil,
            'approved_promo_hours_this_week' => nil,

            'days' => {},
            'weeks' => {}
        }

        return data if @campaign.first_event_at.nil?


        # Initialize the weeks array
        date = @campaign.first_event_at.beginning_of_week
        while date < @campaign.last_event_at
          data['weeks'][date.to_s(:numeric)] = {
            'scheduled_events' => 0,
            'approved_events' => 0,
            'approved_promo_hours' => 0,
            'scheduled_promo_hours' => 0,
            'cumulative_approved_events' => 0,
            'cumulative_scheduled_events' => 0,
            'cumulative_approved_promo_hours' => 0,
            'cumulative_scheduled_promo_hours' => 0
          }
          date = date + 1.week
        end

        # Initialize the days arrray
        data['days'] = {}
        (@campaign.first_event_at.to_date..@campaign.last_event_at.to_date).each{|d| data['days'][d.to_s(:numeric)] ||= {'scheduled_events' => 0, 'approved_events' => 0, 'approved_promo_hours' => 0, 'scheduled_promo_hours' => 0}}

        # Get the events/promo hours data
        tz = Time.zone.now.strftime('%Z')
        date_convert = "to_char(TIMEZONE('UTC', start_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD')"
        scope = Event.where(campaign_id: @campaign).select("count(events.id) as events_count, sum(promo_hours) as promo_hours, #{date_convert} as event_start, events.aasm_state as group_recap_status").group("#{date_convert}, events.aasm_state").order(date_convert)
        weeks_with_approved_events = 0
        previous_week = nil
        scope.each do |event_day|
          date = Timeliness.parse(event_day.event_start, zone: :current)
          day = date.to_s(:numeric)
          data['days'][day]['approved_promo_hours']   = event_day.promo_hours.to_i  if event_day.group_recap_status == 'approved'
          data['days'][day]['scheduled_promo_hours'] += event_day.promo_hours.to_i
          data['days'][day]['approved_events']        = event_day.events_count.to_i if event_day.group_recap_status == 'approved'
          data['days'][day]['scheduled_events']      += event_day.events_count.to_i

          # Add the total to the week
          week = date.beginning_of_week.to_s(:numeric)
          data['weeks'][week]['approved_promo_hours']   += event_day.promo_hours.to_i  if event_day.group_recap_status == 'approved'
          data['weeks'][week]['scheduled_promo_hours']  += event_day.promo_hours.to_i
          data['weeks'][week]['approved_events']        += event_day.events_count.to_i if event_day.group_recap_status == 'approved'
          data['weeks'][week]['scheduled_events']       += event_day.events_count.to_i

          # Totals
          data['approved_events']       += event_day.events_count.to_i  if event_day.group_recap_status == 'approved'
          data['scheduled_events']      += event_day.events_count.to_i
          data['approved_promo_hours']  += event_day.promo_hours.to_i if event_day.group_recap_status == 'approved'
          data['scheduled_promo_hours'] += event_day.promo_hours.to_i

          if week != previous_week and event_day.group_recap_status == 'approved'
            weeks_with_approved_events += 1
            previous_week = week
          end
        end

        scheduled_events = scheduled_promo_hours = approved_events = approved_promo_hours = 0
        data['weeks'].each do |week, values|
          approved_promo_hours += values['approved_promo_hours']
          scheduled_promo_hours += values['scheduled_promo_hours']
          approved_events += values['approved_events']
          scheduled_events += values['scheduled_events']
          # Cumulative events/promo hours
          values['cumulative_approved_promo_hours']   = approved_promo_hours
          values['cumulative_scheduled_promo_hours']  = scheduled_promo_hours
          values['cumulative_approved_events']        = approved_events
          values['cumulative_scheduled_events']       = scheduled_events
        end

        # Avg of approved events/promo hours per week
        data['approved_events_week_avg'] = data['weeks'].values.sum{|v| v['approved_events']}
        data['approved_promo_hours_week_avg']  = data['weeks'].values.sum{|v| v['approved_promo_hours']}

        this_week = Time.zone.now.beginning_of_week.to_s(:numeric)
        if data['weeks'].has_key?(this_week)
          data['approved_events_this_week'] = data['weeks'][this_week]['approved_events']
          data['approved_promo_hours_this_week'] = data['weeks'][this_week]['approved_promo_hours']
        end

        # Compute current and expectation percentages
        total_days = ((@campaign.last_event_at  - @campaign.first_event_at).to_i / 86400).round
        today_days = ((Time.zone.now  - @campaign.first_event_at).to_i / 86400).round

        data['expected_events'] = expected_total =  events_goal > 0 ? events_goal : data['scheduled_events']
        data['remaining_events'] = expected_total - data['approved_events']
        data['remaining_events'] = 0 if data['remaining_events'] < 0
        data['events_percentage'] = data['approved_events'] * 100 / expected_total if expected_total > 0
        data['events_percentage_today'] = [100, today_days * expected_total / total_days].min
        if expected_total > 0 && total_days > 0
          data['expected_events_today'] = today_days * expected_total / total_days                             # How many events are expected to be completed today
          data['events_percentage_today'] = [100, data['expected_events_today'] * 100 / expected_total].min    # and what percentage does that represents
        end


        data['expected_promo_hours'] = expected_total =  promo_hours_goal > 0 ? promo_hours_goal : data['scheduled_promo_hours']
        data['remaining_promo_hours'] = expected_total - data['approved_promo_hours']
        data['remaining_promo_hours'] = 0 if data['remaining_promo_hours'] < 0
        data['promo_hours_percentage'] = data['approved_promo_hours'] * 100 / expected_total if expected_total > 0
        if expected_total > 0 && total_days > 0
          data['expected_promo_hours_today'] = today_days * expected_total / total_days                                   # How many promo hours are expected to be completed today
          data['promo_hours_percentage_today'] = [100, data['expected_promo_hours_today'] * 100 / expected_total].min    # and what percentage does that represents
        end


        # Fetch KPIs data from Solr
        search_params = {
          company_id: current_company.id,
          campaign: @campaign.id,
          status: ['Approved'],
          event_data_stats: true
        }
        search = Event.do_search(search_params, true)

        data['impressions'] = search.stat_response['stats_fields']["impressions_es"]['sum'] rescue 0
        data['interactions'] = search.stat_response['stats_fields']["interactions_es"]['sum'] rescue 0
        data['samples'] = search.stat_response['stats_fields']["samples_es"]['sum'] rescue 0
        data['spent'] = search.stat_response['stats_fields']["spent_es"]['sum'] rescue 0

        data['gender'] = {}
        data['gender']['Female'] = search.stat_response['stats_fields']["gender_female_es"]['mean'] rescue 0
        data['gender']['Male']   = search.stat_response['stats_fields']["gender_male_es"]['mean'] rescue 0

        data['ethnicity'] = {}
        EventData::SEGMENTS_NAMES_MAP[:ethnicity].each do|name, key|
          data['ethnicity'][name] = search.stat_response['stats_fields']["ethnicity_#{key}_es"]['mean'] rescue 0
        end

        # Age results are not stored on Solr :(
        data['age'] = {}
        age_results = EventResult.age.joins(:event).where(events: {aasm_state: 'approved', campaign_id: @campaign}).select('event_results.kpis_segment_id, sum(event_results.scalar_value) AS segment_sum, avg(event_results.scalar_value) AS segment_avg').group('event_results.kpis_segment_id').all
        segments = Kpi.age.kpis_segments
        data['age'] = Hash[segments.map{|s| [s.text, age_results.detect{|r| r.kpis_segment_id == s.id}.try(:segment_avg).try(:to_f) || 0]}]

        data
      end
    end


    def each_campaign_goal
      goals = @campaign.goals.joins(:kpi).where(kpi_id: @campaign.active_kpis).includes(:kpi).all
      totals = EventResult.scoped_by_campaign_id(@campaign).scoped_by_kpi_id(goals.map(&:kpi))
                          .select('count(event_results.id) total_results, sum(scalar_value) as total_value, avg(scalar_value) as avg_value, event_results.kpi_id, event_results.kpis_segment_id')
                          .group('event_results.kpi_id, event_results.kpis_segment_id')
      goals.each do |goal|
        data = totals.detect{|row| row.kpi_id == goal.kpi_id && row.kpis_segment_id == goal.kpis_segment_id }
        if data.nil?
          yield goal, 0, 100, goal.value, 0
        else
          if goal.kpis_segment_id.nil?
            goal_value = goal.value || 0
            total_count = data.total_results.to_i
            remaining_count =  goal_value - data.total_results.to_i
            completed_percentage = total_count * 100 / goal_value rescue 0
            remaining_percentage = 100 - completed_percentage
            yield goal, completed_percentage, remaining_percentage, remaining_count, total_count
          end
        end
      end
    end

    def vertical_progress_bar(complete, today)
      complete = 1 if complete < 1 and complete > 0
      content_tag(:div, class: 'vertical-progress') do
        content_tag(:div, class: 'progress vertical') do
          content_tag(:div, "#{(100 - complete).round}%", class: 'bar bar-remaining', style: "height: #{[0,(100 - complete).round].max}%;") +
          content_tag(:div, "#{complete.round}%", class: 'bar bar-success', style: "height: #{[100,complete.round].min}%;")
        end +
        content_tag(:div, '', class: 'today-line-indicator', style: "bottom: #{today.to_i}%")
      end
    end

    def percentage_remaining_narrative(complete)
      if complete.present?
        if complete < 90
          "This campaign is behind track. You have currently run #{complete.round}% of your target number of events."
        elsif complete >= 90
          "This campaign is approximately on track. You have currently run #{complete.round}% of your target number of events."
        elsif complete > 110
          "This campaign is ahead of track. You have currently run #{complete.round}% of your target number of events."
        elsif complete == 100
          "You have reached the target number of events."
        end
      end
    end

    def events_per_week_narrative(data)
      approved_events_this_week = data['approved_events_this_week']
      approved_events_week_avg = data['approved_events_week_avg']
      if approved_events_this_week.present? && approved_events_week_avg.present?
        lower_percentage_events = approved_events_week_avg - (approved_events_week_avg * 0.10)
        upper_percentage_events = approved_events_week_avg + (approved_events_week_avg * 0.10)

        if approved_events_this_week < lower_percentage_events
          "You have completed #{approved_events_this_week} events this week. This is below average for this campaign."
        elsif approved_events_this_week >= lower_percentage_events && approved_events_this_week <= upper_percentage_events
          "You have completed #{approved_events_this_week} events this week. This is about average for this campaign."
        elsif approved_events_this_week > upper_percentage_events
          "You have completed #{approved_events_this_week} events this week. This is above average for this campaign."
        end
      end
    end

    def promo_hours_per_week_narrative(data)
      approved_promo_hours_this_week = data['approved_promo_hours_this_week']
      approved_promo_hours_week_avg = data['approved_promo_hours_week_avg']
      if approved_promo_hours_this_week.present? && approved_promo_hours_week_avg.present?
        lower_percentage_promo = approved_promo_hours_week_avg - (approved_promo_hours_week_avg * 0.10)
        upper_percentage_promo = approved_promo_hours_week_avg + (approved_promo_hours_week_avg * 0.10)

        if approved_promo_hours_this_week < lower_percentage_promo
          "You have completed #{approved_promo_hours_this_week} promo hours this week. This is below average for this campaign."
        elsif approved_promo_hours_this_week >= lower_percentage_promo && approved_events_this_week <= upper_percentage_promo
          "You have completed #{approved_promo_hours_this_week} promo hours this week. This is about average for this campaign."
        elsif approved_promo_hours_this_week > upper_percentage_promo
          "You have completed #{approved_promo_hours_this_week} promo hours this week. This is above average for this campaign."
        end
      end
    end

    def reach_narrative(data)
      max_ethnicity = data['ethnicity'].max_by{|k,v| v}.first
      max_age = data['age'].max_by{|k,v| v}.first
      max_gender = data['gender'].max_by{|k,v| v}.first

      "The audience primarily was #{max_ethnicity}, #{max_age}, #{max_gender}"
    end

    # def awareness_narrative(statistics)
    #   if statistics.present?
    #     output = []
    #     i = 0
    #     statistics.each do |type, value|
    #       value.sort{|hash_a,hash_b| hash_a[:avg] <=> hash_b[:avg]}
    #       Rails.logger.debug value
    #       output[i] = "[Brand] was the #{type} most likely brand to be purchased in field surveys with X% of consumers highly likely to purchase"
    #       i += 1
    #     end
    #     #     Rails.logger.debug value.inspect
    #     #   end
    #     # statistics.each_with_index do |data, index|
    #     #   Rails.logger.debug data.inspect
    #     #   data.each do |field, value|
    #     #     Rails.logger.debug value.inspect
    #     #   end
    #     #   output[index] = "[Brand] was the #{index} most likely brand to be purchased in field surveys with X% of consumers highly likely to purchase"
    #     # end
    #     output.join('<br/>').html_safe
    #   end
    # end
	end
end