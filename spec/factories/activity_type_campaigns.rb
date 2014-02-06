# == Schema Information
#
# Table name: activity_type_campaigns
#
#  id               :integer          not null, primary key
#  activity_type_id :integer
#  campaign_id      :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :activity_type_campaign do
    activity_type nil
    campaign nil
  end
end
