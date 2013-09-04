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
      data[:impressions_event] = result.impressions.to_i/result.events_count.to_i
      data[:interactions_event] = result.interactions.to_i/result.events_count.to_i
      data[:sampled_event] = result.sampled.to_i/result.events_count.to_i
      data[:spent] = result.spent.to_f
      data[:cost_impression] = result.spent.to_f / result.impressions.to_i
      data[:cost_interaction] = result.spent.to_f / result.interactions.to_i
      data[:cost_sample] = result.spent.to_f / result.sampled.to_i
    end
  end
end