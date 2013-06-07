# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :date_item do
    start_date "01/03/2013"
    end_date "01/23/2013"
    recurrence false
    recurrence_type "daily"
    recurrence_period 1
    recurrence_days %w(monday tuesday)
    date_range_id 1
  end
end
