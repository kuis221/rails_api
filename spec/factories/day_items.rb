# == Schema Information
#
# Table name: day_items
#
#  id          :integer          not null, primary key
#  day_part_id :integer
#  start_time  :time
#  end_time    :time
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :day_item do
    start_time '8:00 AM'
    end_time '5:00 PM'
    day_part_id 1
  end
end
