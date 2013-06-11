# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :day_part do
    name "MyString"
    description "MyText"
    active false
    created_by_id 1
    updated_by_id 1
  end
end
