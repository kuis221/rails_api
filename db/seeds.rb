# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

<<<<<<< HEAD
if AdminUser.where(email:'admin@brandscopic.com').count == 0
	AdminUser.create!(:email => 'admin@brandscopic.com', :password => 'AdminPazBC', :password_confirmation => 'AdminPazBC')
end

c = Company.find_or_create_by_name(name: 'Brandscopic', admin_email: 'admin@brandscopic.com')
r = c.roles.find_or_create_by_name(name: 'Admin')
u =  c.company_users.first.user
u.confirm!
u.password = 'Adminpass12'
u.password_confirmation = 'Adminpass12'
u.save

# Create the user used for the load tests
tu =  User.create({email: 'test@brandscopic.com', first_name: 'Test', last_name: 'User', password: 'TestPass321', password_confirmation: 'TestPass321', country: 'US', state: 'CA', city: 'San Francisco', invitation_accepted_at: Time.now, confirmed_at: Time.now, invitation_token: nil}, without_protection: true)
CompanyUser.create({active: true, user: tu, company_id: c.id, role_id: r.id}, without_protection: true)
tu.confirm!
=======

AdminUser.create!(:email => 'admin@brandscopic.com', :password => 'AdminPazBC', :password_confirmation => 'AdminPazBC') if AdminUser.count == 0

c = Company.find_or_create_by_name(name: 'Brandscopic', admin_email: 'admin@brandscopic.com')
u = User.find_by_email('admin@brandscopic.com')
u.update_attributes({password: 'Adminpass12', password_confirmation: 'Adminpass12', country: 'US', state: 'CA', city: 'San Francisco', invitation_accepted_at: Time.now, confirmed_at: Time.now, invitation_token: nil, time_zone: 'Pacific Time (US & Canada)'}, without_protection: true)
# u.update_column(:encrypted_password, '$2a$10$zm71ctU0VNxKhHflsfPpNeEeMRMV3d/A71o382VYJpWv92Vorvr7W')
#r = c.roles.find_or_create_by_name(name: 'Admin')
#u =  User.create({email: 'admin@brandscopic.com', first_name: 'Admin', last_name: 'Brandscopic', password: 'Adminpass12', password_confirmation: 'Adminpass12', country: 'US', state: 'CA', city: 'San Francisco', invitation_accepted_at: Time.now, confirmed_at: Time.now, invitation_token: nil, time_zone: 'Pacific Time (US & Canada)'}, without_protection: true)
#cu = CompanyUser.create({active: true, user_id: u.id, company_id: c.id, role_id: r.id}, without_protection: true)

# Create the user used for the load tests
tu =  User.create({email: 'test@brandscopic.com', first_name: 'Test', last_name: 'User', password: 'TestPass321', password_confirmation: 'TestPass321', country: 'US', state: 'CA', city: 'San Francisco', invitation_accepted_at: Time.now, confirmed_at: Time.now, invitation_token: nil, time_zone: 'Pacific Time (US & Canada)'}, without_protection: true)
CompanyUser.create({active: true, user_id: tu.id, company_id: c.id, role_id: c.roles.first.id}, without_protection: true)
>>>>>>> 3140877dc146d5db85103f2d981d7d44fcc8d087
