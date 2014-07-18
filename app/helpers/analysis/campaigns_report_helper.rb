include SurveySeriesHelper


module Analysis
	module CampaignsReportHelper
    include ReportsHelper

    def campaigns_events_data
      @campaign_data ||= begin
        data = load_events_and_promo_hours_data

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
        age_results_scope = FormFieldResult.for_kpi(Kpi.age).for_event_campaign(@campaign).
                        where(events: {aasm_state: 'approved'})
        segments = Kpi.age.kpis_segments
        data['age'] = Hash[segments.map do |s|
          [s.text, age_results_scope.average("COALESCE(NULLIF(form_field_results.hash_value -> '#{s.id}', ''), '0')::NUMERIC") || 0]
        end]

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

    def percentage_remaining_narrative(complete, required_progress, metric)
      if complete.present?
        if complete < (required_progress * 0.9)
          "This campaign is behind track. You have currently run #{complete.round}% of your target number of #{metric}."
        elsif complete >= (required_progress * 0.9)
          "This campaign is approximately on track. You have currently run #{complete.round}% of your target number of #{metric}."
        elsif complete > (required_progress * 1.1)
          "This campaign is ahead of track. You have currently run #{complete.round}% of your target number of #{metric}."
        elsif complete >= 100
          "You have reached the target number of #{metric}."
        end
      end
    end

    def events_per_week_narrative(data)
      approved_events_this_week = data['approved_events_this_week'] || 0
      approved_events_week_avg = data['approved_events_week_avg'] || 0
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
      approved_promo_hours_this_week = data['approved_promo_hours_this_week'] || 0
      approved_promo_hours_week_avg = data['approved_promo_hours_week_avg']   || 0
      if approved_promo_hours_this_week.present? && approved_promo_hours_week_avg.present?
        lower_percentage_promo = approved_promo_hours_week_avg - (approved_promo_hours_week_avg * 0.10)
        upper_percentage_promo = approved_promo_hours_week_avg + (approved_promo_hours_week_avg * 0.10)

        if approved_promo_hours_this_week < lower_percentage_promo
          "You have completed #{approved_promo_hours_this_week} promo hours this week. This is below average for this campaign."
        elsif approved_promo_hours_this_week >= lower_percentage_promo && approved_promo_hours_this_week <= upper_percentage_promo
          "You have completed #{approved_promo_hours_this_week} promo hours this week. This is about average for this campaign."
        elsif approved_promo_hours_this_week > upper_percentage_promo
          "You have completed #{approved_promo_hours_this_week} promo hours this week. This is above average for this campaign."
        end
      end
    end

    def reach_narrative(data)
      max_ethnicity = max_age = max_gender = nil
      max_ethnicity = data['ethnicity'].max_by{|k,v| v}.first   if data['ethnicity'].values.max > 0
      max_age = data['age'].max_by{|k,v| v}.first               if data['age'].values.max > 0
      max_gender = data['gender'].max_by{|k,v| v}.first         if data['gender'].values.max > 0

      values = [max_ethnicity, max_age, max_gender].compact
      if values.any?
        "The audience primarily was #{values.join(', ')}"
      end
    end

    def awareness_narrative(statistics)
      if statistics.present? && statistics['aware'].present?
        i = -1
        rankings = ['first', 'second', 'third', 'fourth', 'fifth']
        statistics['aware'].sort_by{|brand, data| -data[:avg] }.map do |k, v|
          "#{k} was the #{rankings[i+=1]} most recognized brand in field surveys with #{v[:avg]}% of the population aware"
        end.join('<br />').html_safe
      end
    end

    def conversion_narrative(statistics)
      i = -1
      rankings = ['first', 'second', 'third', 'fourth', 'fifth']
      if statistics.present? && statistics['5'].present? && statistics['5'].any?
        statistics['5'].sort_by{|brand, data| -data[:avg] }.map do |k, v|
          "#{k} was the #{rankings[i+=1]} most likely brand to be purchased in field surveys with #{v[:avg]}% of consumers highly likely to purchase"
        end.join('<br />').html_safe
      elsif statistics.present? && statistics['4'].present? && statistics['4'].any?
        statistics['4'].sort_by{|brand, data| -data[:avg] }.map do |k, v|
          "#{k} was the #{rankings[i+=1]} most likely brand to be purchased in field surveys with #{v[:avg]}% of consumers likely to purchase"
        end.join('<br />').html_safe
      end
    end


	end
end