object false

node :page do
  params[:page] || 1
end

node :total do
  collection_count
end

child @events => 'results' do

  attributes :id, :start_date, :start_time, :end_date, :end_time, :status, :event_status

  child(:place) do
    attributes :id, :name, :latitude, :longitude, :formatted_address, :country, :state, :state_name, :city, :route, :street_number, :zipcode
  end

  child :campaign do
    attributes :id, :name
  end
end


if params[:page].nil? || params[:page].to_i == 1
  node :facets do
    facets
  end
end