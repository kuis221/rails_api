collection @activities, :object_root => false

attributes id: :id, name: :title

node :allDay do |a|
  false
end

node :start do |a|
  a.start_date.to_s(:full_calendar) unless a.start_date.nil?
end
node :end do |a|
  a.end_date.to_s(:full_calendar) unless a.end_date.nil?
end

node :url do |a|
  activity_url(a)
end