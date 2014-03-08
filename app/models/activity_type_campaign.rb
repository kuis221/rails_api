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

class ActivityTypeCampaign < ActiveRecord::Base
  belongs_to :activity_type
  belongs_to :campaign
end
