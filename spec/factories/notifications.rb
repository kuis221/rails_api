# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    company_user nil
    message "MyString"
    level "MyString"
    path "MyText"
    icon "MyString"
  end
end
