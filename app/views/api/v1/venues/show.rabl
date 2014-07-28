object @venue

attributes :id, :name, :formatted_address, :latitude, :longitude,
           :street_number, :route, :zipcode, :neighborhood, :city,
           :state, :country, :td_linx_code, :events_count, :promo_hours,
           :impressions, :interactions, :sampled, :spent,
           :avg_impressions, :avg_impressions_hour, :avg_impressions_cost

if can?(:view_score, resource)
  attributes :score
end

node do |venue|
    {opening_hours: place_opening_hours(venue.opening_hours)}
end