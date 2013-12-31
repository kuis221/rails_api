collection @members


attributes :id, :name
node do |contactable|
  contactable.is_a?(CompanyUser) ? {description: contactable.role_name, type: 'user'} : {description: contactable.description, type: 'team'}
end