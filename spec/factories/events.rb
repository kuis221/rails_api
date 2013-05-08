# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    campaign_id 1
    start_date "01/23/2019"
    start_time "10:00am"
    end_date "01/23/2019"
    end_time "12:00pm"
    company_id 1
    active true
  end
end
