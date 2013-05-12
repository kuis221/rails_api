collection @events, :root => false, :object_root => false

attributes :id, :start_date,:start_time, :end_date, :end_time, :active

node :start_at do |event|
  event.start_at.to_s
end
node :end_at do |event|
  event.end_at.to_s
end

child(:place) { attributes :name, :latitude, :longitude, :formatted_address }
child(:campaign) { attributes :name }

node(:status) do |event|
  event.active? ? 'Active' : 'Inactive'
end

node(:links) do |event|
  {
    edit: edit_event_path(event),
    show: event_path(event),
    activate: activate_event_path(event),
    deactivate: deactivate_event_path(event)
  }
end