# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    company_id 1
    first_name "Julian"
    last_name "Guerra"
    title "Bar Owner"
    email "somecontact@email.com"
    phone_number "344-23333"
    street1 "12th St."
    street2 ""
    country "US"
    state "CA"
    city "Hollywood"
    zip_code "43212"
  end
end
