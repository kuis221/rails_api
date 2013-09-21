# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :brand do
    sequence(:name) {|n| "Test Brand #{n}" }
    created_by_id 1
    updated_by_id 1
  end
end
