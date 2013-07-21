# == Schema Information
#
# Table name: campaign_form_fields
#
#  id                :integer          not null, primary key
#  campaign_id       :integer
#  kpi_id            :integer
#  ordering          :integer
#  name              :string(255)
#  field_type        :string(255)
#  options           :text
#  section_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  capture_mechanism :string(255)
#

class CampaignFormField < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :kpi
  attr_accessible :name, :options, :ordering, :section_id, :field_type, :kpi_id, :fields_attributes

  serialize :options

  validates :campaign_id, numericality: true, allow_nil: true
  validates :kpi_id, numericality: true, allow_nil: true
  validates :section_id, numericality: true, allow_nil: true
  validates :ordering, numericality: true, presence: true

  delegate :name, :module, to: :kpi, allow_nil: true, prefix: true

  # For field - sections relationship
  has_many :fields, class_name: 'CampaignFormField', foreign_key: :section_id, order: 'ordering ASC', dependent: :destroy
  accepts_nested_attributes_for :fields
end
