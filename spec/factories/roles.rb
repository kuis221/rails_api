# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :role do
    sequence(:name) {|n| "Role #{n}" }
    description "Test Role description"
    company_id 1
    is_admin true
    active true
  end
end
