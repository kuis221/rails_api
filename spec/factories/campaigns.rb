# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campaign do
    sequence(:name) {|n| "Campaign #{n}" }
    description "Test Campaign description"
    aasm_state "active"
    association :company
    created_by_id 1
    updated_by_id 1

    factory :inactive_campaign do
      aasm_state 'inactive'
    end
  end
end
