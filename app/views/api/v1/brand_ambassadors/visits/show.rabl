object @visit

attributes :id, :visit_type_name, :start_date, :end_date, :campaign_name,
           :area_name, :city, :description, :status

child(:company_user => :user) do
  attributes :id, :full_name
end