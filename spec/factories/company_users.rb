# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :company_user do
    company_id 1
    association :user
    role { FactoryGirl.create(:role, company_id: company_id) }
  end
end
