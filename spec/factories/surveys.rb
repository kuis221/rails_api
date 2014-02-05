# == Schema Information
#
# Table name: surveys
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  created_by_id :integer
#  updated_by_id :integer
#  active        :boolean          default(TRUE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :survey do
    event_id nil
    created_by_id 1
    updated_by_id 1
    active true
  end
end
