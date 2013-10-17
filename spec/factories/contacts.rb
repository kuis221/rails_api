# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    company_id 1
    first_name "MyString"
    last_name "MyString"
    title "MyString"
    email "MyString"
    phone_number "MyString"
    street1 "MyString"
    street2 "MyString"
    country "US"
    state "CA"
    city "Holliwood"
    zip_code "43212"
  end
end
