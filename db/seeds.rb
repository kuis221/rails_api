# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


AdminUser.create!(:email => 'admin@brandscopic.com', :password => 'AdminPazBC', :password_confirmation => 'AdminPazBC') if AdminUser.count == 0

c = Company.find_or_create_by_name(name: 'Brandscopic', admin_email: 'admin@brandscopic.com')
u = User.find_by_email('admin@brandscopic.com')
u.update_attributes({password: 'Adminpass12', password_confirmation: 'Adminpass12', country: 'US', state: 'CA', city: 'San Francisco', invitation_accepted_at: Time.now, confirmed_at: Time.now, invitation_token: nil, time_zone: 'Pacific Time (US & Canada)'}, without_protection: true)

# Create the user used for the load tests
tu =  User.create({email: 'test@brandscopic.com', first_name: 'Test', last_name: 'User', password: 'TestPass321', password_confirmation: 'TestPass321', country: 'US', state: 'CA', city: 'San Francisco', invitation_accepted_at: Time.now, confirmed_at: Time.now, invitation_token: nil, time_zone: 'Pacific Time (US & Canada)'}, without_protection: true)
CompanyUser.create({active: true, user_id: tu.id, company_id: c.id, role_id: c.roles.first.id}, without_protection: true)


Kpi.create_global_kpis
