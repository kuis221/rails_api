# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :place do
    name "MyString"
    place_id "MyString"
    formatted_address "MyString"
    latitude 1.5
    longitude 1.5
    zipcode "MyString"
    city "MyString"
    state ""
    country "MyString"
  end
end
