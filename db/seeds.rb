# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

c = Company.find_or_create_by_name(name: 'Brandscopic')
r = c.roles.find_or_create_by_name(name: 'Admin')
u =  User.create({email: 'admin@brandscopic.com', first_name: 'Admin', last_name: 'Brandscopic', password: 'Adminpass12', password_confirmation: 'Adminpass12', aasm_state: 'active', company_id: c.id, role_id: r.id}, without_protection: true)
