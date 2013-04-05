# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :activity do
    name "Test Event"
    start_date_date "02/27/2015"
    start_date_time "03:20 PM"
    end_date_date "02/27/2015"
    end_date_time "05:00 PM"
  end
end
