# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

AdminUser.create!(email: 'admin@brandscopic.com', password: 'AdminPazBC', password_confirmation: 'AdminPazBC') if AdminUser.count == 0

c = Company.create_with(admin_email: 'admin@brandscopic.com').find_or_create_by(name: 'Brandscopic')
u = User.find_by(email: 'admin@brandscopic.com')

u.update_attributes(password: 'Adminpass12', password_confirmation: 'Adminpass12', country: 'US', state: 'CA', city: 'San Francisco', invitation_accepted_at: Time.now, confirmed_at: Time.now, invitation_token: nil, time_zone: 'Pacific Time (US & Canada)')
u.save(validate: false) # Make sure it's saved

Kpi.create_global_kpis
