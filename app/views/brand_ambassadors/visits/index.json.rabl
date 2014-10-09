collection @visits, root: false, object_root: false

attributes visit_type_name: :visit_type_name,
           start_date: :start,
           campaign_name: :campaign_name,
           city: :city,
           campaign_color: :color

node :end do |visit|
  visit.end_date.end_of_day
end

node :url do |visit|
  brand_ambassadors_visit_url(visit)
end

child :company_user do
  attribute :full_name
end