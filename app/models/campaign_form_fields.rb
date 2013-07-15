class CampaignFormFields < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :kpi
  attr_accessible :name, :options, :ordering, :section_id, :type
end
