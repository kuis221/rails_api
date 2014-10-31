collection @events

attributes :id, :start_date, :start_time, :end_date, :end_time

node :campaign do |e|
  { id: e.campaign_id, name: e.campaign_name }
end

child :place do
  attributes :id, :name, :formatted_address, :country, :state_name, :city, :zipcode
end