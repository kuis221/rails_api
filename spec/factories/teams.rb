# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team do
    name "MyString"
    description "MyText"
    created_by_id 1
    updated_by_id 1
    users_count 0
    active true
  end
end
