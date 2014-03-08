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

require 'spec_helper'

describe ActivityTypeCampaign do
  it { should belong_to(:activity_type) }
  it { should belong_to(:campaign) }
end