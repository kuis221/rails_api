collection @activities, :object_root => false

attributes id: :id

node :title do |a|
  "#{a.start_date.to_s(:time_only)} #{a.name}"
end

node :start do |a|
  a.start_date.to_s(:full_calendar)
end
node :end do |a|
  a.end_date.to_s(:full_calendar)
end

node :url do |a|
  activity_url(a)
end