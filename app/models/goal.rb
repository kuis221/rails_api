# == Schema Information
#
# Table name: goals
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  kpi_id      :integer
#  segment_id  :integer
#  value       :decimal(, )
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Goal < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :kpi
  belongs_to :segment
  attr_accessible :value, :campaign_id, :kpi_id
end
