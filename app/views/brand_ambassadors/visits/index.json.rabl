collection @visits, :root => false, :object_root => false

attributes :name => :title, :start_date => :start

node :end do |visit|
  visit.end_date.end_of_day
end

child :company_user do
  attribute :full_name
end