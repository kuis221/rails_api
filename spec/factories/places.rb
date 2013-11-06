# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :place do
    sequence(:name) {|n| "Place #{n}" }
    sequence(:place_id)
    sequence(:reference) {|n| "$aojnoiweksadk-o19290f0i2ief0-#{n}"}
    formatted_address "123 My Street"
    latitude 1.5
    longitude 1.5
    zipcode "12345"
    city "New York City"
    state "NY"
    country "US"
    do_not_connect_to_api true

    after(:build) {|u| u.types ||= ['establishment'] }
  end
end
