# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :day_item do
    start_time "8:00 AM"
    end_time "5:00 PM"
    day_part_id 1
  end
end
