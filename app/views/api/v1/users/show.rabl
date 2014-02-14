object @user

attributes :id, :first_name, :last_name, :full_name, :email, :phone_number, :street_address, :unit_number, :city, :state, :zip_code, :time_zone
attributes :country_name => :country

child :role do
  attributes :id, :name
end

child :teams do
  attributes :id, :name
end