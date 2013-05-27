# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :role do
    name "Test Role"
    description "Test Role description"
    permissions "Test Role permissions"
    company_id 1
    active true
  end
end
