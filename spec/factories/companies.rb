# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :company do
    sequence(:name) {|n| "Company #{n}"}
    no_create_admin true

    factory :company_with_user do
      no_create_admin false
      sequence(:admin_email) { |n| "testadminuser#{n}@brandscopic.com" }
    end
  end
end
