include SurveySeriesHelper

module Analysis
	module CampaignsReportHelper
    def campaigns_events_data(campaign)
      @campaign_data ||= begin
        search_params = {
          company_id: current_company.id,
          campaign: campaign.id,
          facet_date_period: 604799,  # One week in seconds (minus 1 second)
          facet_date_start:  campaign.first_event_at.beginning_of_week,
          facet_date_end:    campaign.last_event_at.end_of_week,
          event_data_stats: true
        }

        goal = @campaign.goals.for_kpis([Kpi.events]).first.try(:value) || 0

        # First search without the status filter to know how many scheduled events are on each week
        search = Event.do_search(search_params, true)

        data = {'total' => search.total, 'approved' => 0, 'approved_percentage' => 0, 'today' => 0, 'today_percentage' => 0, 'goal' => goal, 'weeks' => {}}
        search.facet(:status).rows.each{|facet| data[facet.value.downcase] = facet.count}

        # Initialize the
        date = campaign.first_event_at.beginning_of_week
        while date < campaign.last_event_at
          data['weeks'][date.to_s(:numeric)] ||= {'scheduled' => 0, 'approved' => 0, 'promo_hours' => 0, 'promo_hours' => 0}
          date = date + 1.week
        end

        # Update the weeks with scheduled events
        search.facet(:start_at).rows.map{|facet| data['weeks'][facet.value.first.to_s(:numeric)]['scheduled'] = facet.count }

        data['expected_total'] = expected_total =  goal > 0 ? goal : search.total
        data['remaining'] = expected_total - data['approved']
        data['remaining'] = 0 if data['remaining'] < 0

        data['approved_percentage'] = data['approved'] * 100 / expected_total if expected_total > 0
        total_days = ((campaign.last_event_at  - campaign.first_event_at).to_i / 86400).round
        today_days = ((Time.now  - campaign.first_event_at).to_i / 86400).round
        if total_days > 0
          data['today'] = today_days * expected_total / total_days
          data['today_percentage'] = [100, data['today'] * 100 / expected_total].min if expected_total > 0
        end

        # Then search only the Approved events
        search = Event.do_search(search_params.merge({status: ['Approved']}), true)
        search.facet(:start_at).rows.map{|facet| data['weeks'][facet.value.first.to_s(:numeric)]['approved'] = facet.count }


        # TODO: Search for an optimal way to do this:
        scope = Event.where(campaign_id: campaign, aasm_state: 'approved')
        data['promo_hours'] = 0
        search.facet(:start_at).rows.map do |facet|
          data['promo_hours'] += promo_hours = scope.where(['events.start_at between ? and ?', facet.value.first, facet.value.last]).sum(:promo_hours)
          data['weeks'][facet.value.first.to_s(:numeric)]['promo_hours'] = promo_hours
        end
        data['total_promo_hours'] = data['promo_hours']   # Scheduled + Approved

        # Events on the future
        scope = Event.where(campaign_id: campaign).where(['aasm_state <> ?', 'approved'])
        date = Time.zone.now.end_of_week + 1.second
        while date <= campaign.last_event_at.beginning_of_week
          data['total_promo_hours'] += promo_hours = scope.where(['events.start_at between ? and ?', date, date.end_of_week]).sum(:promo_hours)
          data['weeks'][date.to_s(:numeric)]['scheduled_promo_hours'] = promo_hours
          date += 1.week
        end

        goal = @campaign.goals.for_kpis([Kpi.promo_hours]).first.try(:value) || 0
        data['promo_hours_expected_total'] = expected_total =  goal > 0 ? goal : data['total_promo_hours']
        data['promo_hours_remaining'] = expected_total - data['promo_hours']
        data['promo_hours_remaining'] = 0 if data['promo_hours_remaining'] < 0
        data['promo_hours_percentage'] = data['promo_hours'] * 100 / expected_total if expected_total > 0
        data['promo_hours_percentage'] ||= 0
        data['promo_hours_today'] = [100, today_days * expected_total / total_days].min if total_days > 0

        data['promo_hours'] = search.stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
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
        age_results = EventResult.age.joins(:event).where(events: {aasm_state: 'approved', campaign_id: campaign}).select('event_results.kpis_segment_id, sum(event_results.scalar_value) AS segment_sum, avg(event_results.scalar_value) AS segment_avg').group('event_results.kpis_segment_id').all
        segments = Kpi.age.kpis_segments
        data['age'] = Hash[segments.map{|s| [s.text, age_results.detect{|r| r.kpis_segment_id == s.id}.try(:segment_avg).try(:to_f) || 0]}]

        # Set the cumulative totals
        approved = scheduled = promo_hours = 0
        data['weeks'].each do |week, values|
          values['cumulative_approved'] = approved += values['approved']
          values['cumulative_scheduled'] = scheduled += values['scheduled']
          values['cumulative_promo_hours'] = promo_hours += values['promo_hours']
        end

        data
      end
    end


    def vertical_progress_bar(complete, today)
      content_tag(:div, class: 'vertical-progress') do
        content_tag(:div, class: 'progress vertical') do
          content_tag(:div, "#{(100 - complete).round}%", class: 'bar bar-remaining', style: "height: #{[0,(100 - complete).round].max}%;") +
          content_tag(:div, "#{complete.round}%", class: 'bar bar-success', style: "height: #{[100,complete.round].min}%;")
        end +
        content_tag(:div, '', class: 'today-line-indicator', style: "bottom: #{today.to_i}%")
      end
    end
	end
end