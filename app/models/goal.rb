# == Schema Information
#
# Table name: goals
#
#  id              :integer          not null, primary key
#  campaign_id     :integer
#  kpi_id          :integer
#  kpis_segment_id :integer
#  value           :decimal(, )
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Goal < ActiveRecord::Base
  belongs_to :goalable, polymorphic: true
  belongs_to :parent, polymorphic: true
  belongs_to :kpi
  belongs_to :kpis_segment
  attr_accessible :value, :goalable_id, :goalable_type, :parent_id, :parent_type, :kpi_id


  validate :goalable_id, presence: true, numericality: true
  validate :goalable_type, presence: true
  validate :kpi_id, presence: true, numericality: true
  validate :kpis_segment_id, numericality: true, allow_nil: true

  scope :in, lambda{|parent| where(parent_type: parent.class.name, parent_id: parent.id) }
end
