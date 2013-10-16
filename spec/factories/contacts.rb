# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    company_id 1
    first_name "MyString"
    last_name "MyString"
    title "MyString"
    email "MyString"
    phone "MyString"
    address1 "MyString"
    address2 "MyString"
    country "MyString"
    state "MyString"
    city "MyString"
    zip_code "MyString"
  end
end
