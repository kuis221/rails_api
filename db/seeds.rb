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



Kpi.create({name: 'Promo Hours', kpi_type: 'promo_hours', description: 'Total duration of events', capture_mechanism: '', company_id: nil, 'module' => ''}, without_protection: true)
Kpi.create({name: 'Events', kpi_type: 'events_count', description: 'Number of events executed', capture_mechanism: '', company_id: nil, 'module' => ''}, without_protection: true)
Kpi.create({name: 'Impressions', kpi_type: 'number', description: 'Total number of consumers who come in contact with an event', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
Kpi.create({name: 'Interactions', kpi_type: 'number', description: 'Total number of consumers who directly interact with an event', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
Kpi.create({name: 'Samples', kpi_type: 'number', description: 'Number of consumers who try a product sample', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
gender_kpi = Kpi.create({name: 'Gender', kpi_type: 'percentage', description: 'Number of consumers who try a product sample', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
age_kpi = Kpi.create({name: 'Age', kpi_type: 'percentage', description: 'Percentage of attendees who are within a certain age range', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
ethnicity_kpi = Kpi.create({name: 'Ethnicity/Race', kpi_type: 'percentage', description: 'Percentage of attendees who are of a certain ethnicity or race', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
Kpi.create({name: 'Cost', kpi_type: 'number', description: 'Total cost of an event', capture_mechanism: 'currency', company_id: nil, 'module' => 'expenses'}, without_protection: true)
Kpi.create({name: 'Photos', kpi_type: 'photos', description: 'Total number of photos uploaded to an event', capture_mechanism: '', company_id: nil, 'module' => 'photos'}, without_protection: true)
Kpi.create({name: 'Videos', kpi_type: 'videos', description: 'Total number of photos uploaded to an event', capture_mechanism: '', company_id: nil, 'module' => 'videos'}, without_protection: true)
Kpi.create({name: 'Surveys', kpi_type: 'number', description: 'Total number of surveys completed for a campaign', capture_mechanism: 'integer', company_id: nil, 'module' => 'surveys'}, without_protection: true)
Kpi.create({name: 'Competitive Analysis', kpi_type: 'number', description: 'Total number of competitive analyses created for a campaign', capture_mechanism: 'integer', company_id: nil, 'module' => 'competitive_analysis'}, without_protection: true)

['< 5 year', '5 - 9', '10 - 14', '15 - 19', '20 - 24', '25 - 29', '30 - 34', '35 - 39', '40 - 44', '45 - 49', '50 - 54', '55 - 59', '60 - 64', '65 - 69', '70+'].each do |segment|
  age_kpi.kpis_segments.create(text: segment)
end

['Female', 'Male'].each do |segment|
  gender_kpi.kpis_segments.create(text: segment)
end

['Asian', 'Black / African American', 'Hispanic / Latino', 'Native American', 'White'].each do |segment|
  ethnicity_kpi.kpis_segments.create(text: segment)
end