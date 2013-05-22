object false
#collection @events, :root => false, :object_root => false

node :total do
  @total_objects
end

node :items do
  @events.map{|event| {
    :id => event.id,
    :start_date => event.start_date,
    :start_time => event.start_time,
    :end_date => event.end_date,
    :end_time => event.end_time,
    :active=> event.active,
    :start_at => event.start_at.to_s,
    :end_at => event.end_at.to_s,
    :place => {
        :name => event.place_name || '',
        :latitude => event.place_latitude || '',
        :longitude => event.place_longitude || '',
        :formatted_address => event.place_formatted_address || ''
    },
    :campaign => { :name => event.campaign_name },
    :status => event.active? ? 'Active' : 'Inactive',
    :links => {
        edit: edit_event_path(event),
        show: event_path(event),
        activate: activate_event_path(event),
        deactivate: deactivate_event_path(event)
    }
  }}
end
