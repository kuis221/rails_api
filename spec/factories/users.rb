# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    first_name 'Test'
    last_name 'User'
    sequence(:email) {|n| "testuser#{n}@brandscopic.com" }
    user_group_id 1
    password 'changeme123'
    password_confirmation 'changeme123'
    city 'Curridabat'
    state 'SJ'
    country 'CR'
  end
end
