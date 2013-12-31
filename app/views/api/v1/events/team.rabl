collection @members

node do |member|
  if member.is_a?(CompanyUser)
    node(:type) { :user }
    partial "api/v1/users/user", :object => member
  else
    node(:type) { :team }
    partial "api/v1/teams/team", :object => member
  end
end
