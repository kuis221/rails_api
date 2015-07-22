object @event

node :counters do |event|
  data = {}
  data[:contacts] = { count: event.contact_events.count, min: nil, max: nil }
  data[:user_tasks] = { count: event.tasks.active.assigned_to(current_company_user).count, min: nil, max: nil }
  data[:team_tasks] = { count: event.tasks.active.count - data[:user_tasks][:count], min: nil, max: nil }
  data[:documents] = { count: event.documents.count, min: nil, max: nil }
  data[:activities] = { count: event.activities.active.count, min: nil, max: nil }
  data[:attendance] = { count: event.invites.active.count, min: nil, max: nil }
  data[:photos] = { count: event.photos.active.count, min: module_range_val(event, 'photos', 'range_min'), max: module_range_val(event, 'photos', 'range_max') }
  data[:expenses] = { count: event.event_expenses.count, min: module_range_val(event, 'expenses', 'range_min'), max: module_range_val(event, 'expenses', 'range_max') }
  data[:comments] = { count: event.comments.count, min: module_range_val(event, 'comments', 'range_min'), max: module_range_val(event, 'comments', 'range_max') }
  data
end