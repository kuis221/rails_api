# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :date_range do
    sequence(:name) {|n| "Date Range #{n}"}
    description "Some Date Range description"
    active false
    company_id 1
    created_by_id 1
    updated_by_id 1
  end
end
