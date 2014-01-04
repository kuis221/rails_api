collection @contacts

node do |member|
  if member.is_a?(CompanyUser)
    node(:type) { :user }
    partial "api/v1/users/user", :object => member
  else
    node(:type) { :contact }
    partial "api/v1/contacts/contact", :object => member
  end
end