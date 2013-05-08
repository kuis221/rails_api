# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    first_name 'Test'
    last_name 'User'
    sequence(:email) {|n| "testuser#{n}@brandscopic.com" }
    user_group_id 1
    password 'Changeme123'
    password_confirmation 'Changeme123'
    city 'Curridabat'
    state 'SJ'
    country 'CR'
    company_id 1
    aasm_state 'active'
  end
end
