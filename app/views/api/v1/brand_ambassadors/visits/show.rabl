object @visit

attributes :id, :campaign_id, :area_id, :visit_type, :visit_type_name, 
		   :start_date, :end_date, :city, :description, :status

child(:company_user => :user) do
  attributes :id, :full_name
end

node :campaign do |visit|
{id: visit.campaign_id, name: visit.campaign_name}
end

child :campaign do
  attributes :id, :name
end

child :area do
  attributes :id, :name
end