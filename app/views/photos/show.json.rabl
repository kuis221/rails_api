object @photo

attributes :id

node(:title) { @photo.attachable.campaign_name }
node(:date) { format_date_range(@photo.attachable.start_at, @photo.attachable.end_at, { date_separator: '<br>' }) }
node(:address) { @photo.attachable.place_name_with_location('<br>') }
node(:status) { @photo.active? }
node(:rating) { @photo.rating }
node(:tags) { to_select2_tag_format(@photo.tags) }
node(:permissions) { photo_permissions(@photo) }
node(:urls) do
  {
    event: event_path(@photo.attachable),\
    deactivate: deactivate_event_photo_path(@photo.attachable, @photo),\
    activate: activate_event_photo_path(@photo.attachable, @photo),\
    download: @photo.download_url\
  }
end
