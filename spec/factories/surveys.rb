# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :survey do
    event_id nil
    created_by_id 1
    updated_by_id 1
    active true
  end
end
