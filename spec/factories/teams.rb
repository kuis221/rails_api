# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team do
    sequence(:name) {|n| "Team #{n}" }
    description "Team description"
    created_by_id 1
    updated_by_id 1
    active true
    company_id 1
  end
end
