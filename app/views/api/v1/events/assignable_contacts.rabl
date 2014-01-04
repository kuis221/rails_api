collection @contacts


attributes :id, :full_name
node do |contactable|
  contactable.is_a?(CompanyUser) ? {title: contactable.role_name, type: 'user'} : {title: contactable.title, type: 'contact'}
end