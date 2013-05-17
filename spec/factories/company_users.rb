# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :company_user do
    company_id 1
    user_id 1
    role_id 1
  end
end
