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
#  title           :string(255)
#  start_date      :date
#  due_date        :date
#

class Goal < ActiveRecord::Base
  belongs_to :goalable, polymorphic: true
  belongs_to :parent, polymorphic: true
  belongs_to :kpi
  belongs_to :kpis_segment
  belongs_to :activity_type

  validates :goalable_id, presence: true, numericality: true
  validates :goalable_type, presence: true
  validates :kpi_id, numericality: true, presence: true, if: "activity_type_id.blank?"
  validates :kpis_segment_id, numericality: true, allow_nil: true
  validates :activity_type_id, numericality: true, if: "kpi_id.blank?"
  validates :value, numericality: true, allow_nil: true

  validates_datetime :start_date, allow_nil: true, allow_blank: true
  validates_datetime :due_date, allow_nil: true, allow_blank: true, :on_or_after => :start_date

  scope :in, lambda{|parent| where(parent_type: parent.class.name, parent_id: parent.id) }
  scope :base, lambda{ where('parent_type is null') }

  before_validation :set_kpi_id

  protected

    def set_kpi_id
      if self.kpi_id.nil? && self.kpis_segment_id.present?
        self.kpi_id = self.kpis_segment.try(:kpi_id)
      end
    end
end
