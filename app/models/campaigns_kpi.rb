# == Schema Information
#
# Table name: campaigns_kpis
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  kpi_id      :integer
#

class CampaignsKpi < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :kpi
  # attr_accessible :title, :body
end
