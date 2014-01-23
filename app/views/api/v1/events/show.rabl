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

child(venue: :place) do
  attributes :id, :name, :latitude, :longitude, :formatted_address, :country, :state, :state_name, :city, :route, :street_number, :zipcode
end

child :campaign do
  attributes :id, :name
end

node :actions do |event|
  actions = []
  actions.push 'enter post event data' if can?(:view_data, event) && can?(:edit_data, event)
  actions.push 'upload photos' if event.campaign.active_field_types.include?('photos') && can?(:photos, event) && can?(:create_photo, event)
  actions.push 'conduct surveys' if event.campaign.active_field_types.include?('surveys') && can?(:surveys, event) && can?(:create_survey, event)
  actions.push 'enter expenses' if event.campaign.active_field_types.include?('expenses') && can?(:expenses, event) && can?(:create_expense, event)
  actions.push 'gather comments' if event.campaign.active_field_types.include?('comments') && can?(:comments, event) && can?(:create_comment, event)
  actions
end

node :tasks_late_count do |event|
  event.tasks.late.count
end

node :tasks_due_today_count do |event|
  event.tasks.due_today.count
end