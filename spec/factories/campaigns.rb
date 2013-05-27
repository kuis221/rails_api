# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campaign do
    sequence(:name) {|n| "Campaign #{n}" }
    description "Test Campaign description"
    aasm_state "active"
    company_id 1
  end
end
