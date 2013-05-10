# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :admin_user do
    sequence(:email) {|n| "testuser#{n}@brandscopic.com" }
    password 'Changeme123'
    password_confirmation 'Changeme123'
  end
end
