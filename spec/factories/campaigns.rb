# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campaign do
    name "Test Campaign"
    description "Test Campaign description"
    aasm_state "active"
  end
end
