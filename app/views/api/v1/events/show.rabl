object @event

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

child(:place) do
  attributes :id, :name, :latitude, :longitude, :formatted_address, :country, :state, :state_name, :city, :route, :street_number, :zipcode
end

child :campaign do
  attributes :id, :name
end