# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report do
    company_id 1
    sequence(:name) {|n| "Team #{n}" }
    description "Team description"
    created_by_id 1
    updated_by_id 1
    active true
  end
end
