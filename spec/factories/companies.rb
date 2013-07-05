# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :company do
    sequence(:name) {|n| "Company #{n}"}
    sequence(:admin_email) {|n| "testadminuser#{n}@brandscopic.com"}
  end
end
