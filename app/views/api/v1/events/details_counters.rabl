object @event

node :counters do |event|
  data = {}
  data[:contacts] = event.contact_events.count
  data[:activities] = event.activities.active.count
  data[:photos] = event.photos.active.count
  data[:expenses] = event.event_expenses.count
  data[:comments] = event.comments.count
  data
end