# == Schema Information
#
# Table name: goals
#
#  id               :integer          not null, primary key
#  kpi_id           :integer
#  kpis_segment_id  :integer
#  value            :decimal(, )
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  goalable_id      :integer
#  goalable_type    :string(255)
#  parent_id        :integer
#  parent_type      :string(255)
#  title            :string(255)
#  start_date       :date
#  due_date         :date
#  activity_type_id :integer
#

class Goal < ActiveRecord::Base
  belongs_to :goalable, polymorphic: true
  belongs_to :parent, polymorphic: true
  belongs_to :kpi
  belongs_to :kpis_segment
  belongs_to :activity_type

  validates :goalable_id, presence: true, numericality: true
  validates :goalable_type, presence: true
  validates :kpi_id, numericality: true, presence: true, unless: :activity_type_id
  validates :kpis_segment_id, numericality: true, allow_nil: true
  validates :activity_type_id, numericality: true, presence: true, unless: :kpi_id
  validates :value, numericality: true, allow_nil: true

  validates :kpi_id, uniqueness: { scope: [:parent_id, :parent_type, :goalable_id, :goalable_type, :kpis_segment_id] }, if: :kpi_id

  validates :due_date, date: { on_or_after: :start_date }

  scope :for_areas, ->(areas) { where(goalable_type: 'Area', goalable_id: areas) }
  scope :for_staff, ->(user_ids, team_ids) { where('(goalable_type = ? and goalable_id in (?)) OR (goalable_type = ? and goalable_id in (?))', 'CompanyUser', user_ids, 'Team', team_ids) }
  scope :for_areas_and_places, ->(area_ids, place_ids) { where('(goalable_type = ? and goalable_id in (?)) OR (goalable_type = ? and goalable_id in (?))', 'Area', area_ids, 'Place', place_ids) }
  scope :for_users_and_teams, -> { where(goalable_type: ['CompanyUser', 'Team']) }
  scope :in, ->(parent) { where(parent_type: parent.class.name, parent_id: parent.id) }
  scope :for, ->(goalable) { where(goalable_type: goalable.class.name, goalable_id: goalable.id) }
  scope :base, -> { where('parent_type is null') }
  scope :with_value, -> { where('value is not null and value <> 0') }

  before_validation :set_kpi_id

  protected

    def set_kpi_id
      if self.kpi_id.nil? && self.kpis_segment_id.present?
        self.kpi_id = self.kpis_segment.try(:kpi_id)
      end
    end
end
