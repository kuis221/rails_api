collection @events, :root => false, :object_root => false

attribute :id, :start_date, :start_at, :end_at, :end_date, :active

child :campaign do
  attribute :id, :name
end

child :place do
  attribute :id, :name, :latitude, :longitude, :formatted_address
end

node :formatted_date do |event|
  format_date_range(event.start_at, event.end_at)
end

node :links do |event|
  {
    show: event_path(event),
    edit: edit_event_path(event),
  }
end