# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :area do
    name "MyString"
    description "MyText"
    active true
    created_by_id 1
    updated_by_id 1
    company_id 1
  end
end
