# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :place do
    sequence(:name) {|n| "Place #{n}" }
    place_id "12313"
    reference '#$aojnoiweksadk-o19290f0i2ief0'
    formatted_address "123 My Street"
    latitude 1.5
    longitude 1.5
    zipcode "12345"
    city "New York City"
    state "NY"
    country "US"
  end
end
