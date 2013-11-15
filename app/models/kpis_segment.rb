# == Schema Information
#
# Table name: kpis_segments
#
#  id         :integer          not null, primary key
#  kpi_id     :integer
#  text       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class KpisSegment < ActiveRecord::Base
  belongs_to :kpi
  has_many :goals, dependent: :destroy
  has_many :event_results, dependent: :destroy
  attr_accessible :text, :goals_attributes

  accepts_nested_attributes_for :goals

  before_destroy :check_results_for_segment

  validates_associated :goals

  validates :text, presence: true, uniqueness: {scope: :kpi_id}

  def has_results?
    EventResult.where(kpi_id: kpi_id ).where('event_results.value=? or event_results.kpis_segment_id=?', self.id.to_s, self.id).count > 0
  end


  protected

    def check_results_for_segment
      errors.add :base, "cannot delete with results" if has_results?

      errors.blank?
    end
end
