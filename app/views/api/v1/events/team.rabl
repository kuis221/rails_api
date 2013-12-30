object false

child @users => :users do
  attributes :id, :first_name, :last_name, :full_name, :role_name
end

child @teams => :teams do
  attributes :id, :name, :description
end