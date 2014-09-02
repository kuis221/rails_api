collection @visits, :root => false, :object_root => false

attributes :name => :title, :start_date => :start, :end_date => :end

child :company_user do
  attribute :full_name
end