# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :day_part do
    sequence(:name) {|n| "Day Part #{n}"}
    description "Some Day Part description"
    active false
    created_by_id 1
    updated_by_id 1
  end
end
