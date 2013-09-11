include SurveySeriesHelper


module Analysis
	module CampaignsReportHelper
    include ReportsHelper

    def campaigns_events_data
      @campaign_data ||= begin
        data = add_events_promo_hours_info_to(data)

        return data if @campaign.first_event_at.nil?

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