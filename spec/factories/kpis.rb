# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :kpi do
    name "MyString"
    description "MyText"
    type ""
    capture "MyString"
    active false
  end
end
