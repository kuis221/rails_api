# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :data_extract do
    type ""
    company nil
    active false
    sharing "MyString"
    name "MyString"
    description "MyText"
    filters "MyText"
    columns "MyText"
    created_by nil
  end
end
