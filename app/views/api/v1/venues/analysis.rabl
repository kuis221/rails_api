object @venue

node :overview do |resource|
  {
    events: resource.events_count,
    promo_hours: resource.promo_hours,
    impressions: resource.impressions,
    interactions: resource.interactions,
    sampled: resource.sampled,
    narrative: venue_score_narrative(resource)
  }
end

node do |resource|
  resource.overall_graphs_data.reject{|k, v| [:cost_impression, :impressions_promo].include?(k)}
end

node :trends_by_week do |resource|
  {
    narrative: venue_trend_week_day_narrative(resource)
  }.merge( resource.overall_graphs_data.select{|k, v| [:cost_impression, :impressions_promo].include?(k)} )
end