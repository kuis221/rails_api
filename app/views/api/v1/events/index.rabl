object false

node :page do
  params[:page] || 1
end

node :total_pages do
  total_pages
end

node :total do
  collection_count
end

child @events => 'results' do

  attributes :id, :start_date, :start_time, :end_date, :end_time, :status

  node :event_status do |event|
    if event.unsent?
      if event.is_late?
        'Late'
      elsif event.in_past?
        'Due'
      else
        'Scheduled'
      end
    else
      event.event_status
    end
  end

  child(venue: :place) do
    attributes :id, :name, :latitude, :longitude, :formatted_address, :country, :state, :state_name, :city, :route, :street_number, :zipcode
  end

  node :campaign do |e|
    {id: e.campaign_id, name: e.campaign_name}
  end
end


if params[:page].nil? || params[:page].to_i == 1
  node :facets do
    facets
  end
end