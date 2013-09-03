# == Schema Information
#
# Table name: goals
#
#  id              :integer          not null, primary key
#  kpi_id          :integer
#  kpis_segment_id :integer
#  value           :decimal(, )
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  goalable_id     :integer
#  goalable_type   :string(255)
#  parent_id       :integer
#  parent_type     :string(255)
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
  scope :base, lambda{ where('parent_type is null') }
end
