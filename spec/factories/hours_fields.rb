# == Schema Information
#
# Table name: hours_fields
#
#  id         :integer          not null, primary key
#  venue_id   :integer
#  day        :integer
#  hour_open  :string(255)
#  hour_close :string(255)
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :hours_field do
  end
end
