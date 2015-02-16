collection @activities

attribute :id, :activity_date

child(:activity_type) do
  attributes :id, :name
end

child(:company_user) do
  attributes :id, :full_name
end