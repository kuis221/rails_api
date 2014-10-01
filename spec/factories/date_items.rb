# == Schema Information
#
# Table name: date_items
#
#  id                :integer          not null, primary key
#  date_range_id     :integer
#  start_date        :date
#  end_date          :date
#  recurrence        :boolean          default(FALSE)
#  recurrence_type   :string(255)
#  recurrence_period :integer
#  recurrence_days   :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :date_item do
    start_date '01/01/2013'
    end_date '01/01/2013'
    recurrence false
    recurrence_type 'daily'
    recurrence_period 1
    recurrence_days %w(monday tuesday)
    date_range_id 1
  end
end
