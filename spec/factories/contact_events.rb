# == Schema Information
#
# Table name: contact_events
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  contactable_id   :integer
#  contactable_type :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact_event do
    contactable nil
    event nil
  end
end
