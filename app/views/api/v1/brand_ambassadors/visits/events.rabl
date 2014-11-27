collection @events

attributes :id, :start_date, :start_time, :end_date, :end_time, :status

node :event_status do |event|
  if event.unsent?
    if event.late?
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

node :campaign do |e|
  { id: e.campaign_id, name: e.campaign_name }
end

child :place do
  attributes :id, :name, :formatted_address, :country, :state_name, :city, :zipcode
end