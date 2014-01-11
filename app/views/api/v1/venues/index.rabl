object false

node :page do
  params[:page] || 1
end

node :total do
  collection_count
end

child @venues => 'results' do
  attributes :id, :name, :formatted_address, :latitude, :longitude,
             :street_number, :route, :zipcode, :neighborhood, :city,
             :state, :country, :td_linx_code, :events_count, :promo_hours,
             :impressions, :interactions, :sampled, :spent, :score,
             :avg_impressions, :avg_impressions_hour, :avg_impressions_cost
end


if params[:page].nil? || params[:page].to_i == 1
  node :facets do
    facets
  end
end