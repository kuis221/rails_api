# == Schema Information
#
# Table name: campaign_form_fields
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  kpi_id      :integer
#  ordering    :integer
#  name        :string(255)
#  field_type  :string(255)
#  options     :text
#  section_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CampaignFormField < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :kpi
  attr_accessible :name, :options, :ordering, :section_id, :field_type, :kpi_id

  serialize :options

  delegate :slug, :name, :module, to: :kpi, allow_nil: true, prefix: true
end
