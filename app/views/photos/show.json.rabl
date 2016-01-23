object @photo

event = @photo.attachable
source_title = 'Event Photo Gallery'
source_type = 'gallery'
source_url = @photo.attachable_type == 'Event' ? event_path(@photo.attachable) + '#event-photos' : ''
if @photo.attachable_type == 'FormFieldResult'
  if @photo.attachable.resultable_type == 'Activity'
    source_title = @photo.attachable.resultable.activity_type.name
    source_type = 'activity_' + @photo.attachable.resultable.activitable_type.downcase
    source_url = activity_path(@photo.attachable.resultable)
    event = Event.find(@photo.attachable.resultable.activitable_id)
  elsif @photo.attachable.resultable_type == 'Event'
    source_title = 'Post Event Recap'
    source_type = 'per'
    source_url = event_path(@photo.attachable.resultable) + '#event-per'
    event = @photo.attachable.resultable
  end
end

venue_url = nil
if event.place
  venue = Venue.find_by(company_id: current_company.id, place_id: event.place.id)
  venue_url = venue_path(venue) if venue.present?
end

attributes :id

node(:title) { event.campaign_name }
node(:date) { format_date_with_time(event.start_at, true) }
node(:address) { event.place_name_with_location('<br>') }
node(:status) { @photo.active? }
node(:rating) { @photo.rating }
node(:tags) { to_select2_tag_format(@photo.tags) }
node(:permissions) { photo_permissions(@photo) }
node(:source) do
  {
    title: source_title,\
    type: source_type,\
    url: source_url\
  }
end
node(:urls) do
  {
    event: event_path(event),\
    venue: venue_url,\
    deactivate: deactivate_event_photo_path(event, @photo),\
    activate: activate_event_photo_path(event, @photo),\
    download: @photo.download_url\
  }
end
