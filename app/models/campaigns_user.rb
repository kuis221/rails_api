# == Schema Information
#
# Table name: campaigns_users
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  user_id     :integer
#

class CampaignsUser < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :user
end
