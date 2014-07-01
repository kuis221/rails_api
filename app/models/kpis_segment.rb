# == Schema Information
#
# Table name: kpis_segments
#
#  id         :integer          not null, primary key
#  kpi_id     :integer
#  text       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ordering   :integer
#

class KpisSegment < ActiveRecord::Base
  belongs_to :kpi
  has_many :goals, dependent: :destroy

  accepts_nested_attributes_for :goals

  before_destroy :check_results_for_segment

  validates_associated :goals

  validates :text, presence: true, uniqueness: {scope: :kpi_id}

  def has_results?
    FormFieldResult.for_kpi(kpi_id).where("form_field_results.value='#{self.id}' or (form_field_results.hash_value ? '#{self.id}' AND form_field_results.hash_value->'#{self.id}' <> '')").count > 0
  end


  protected

    def check_results_for_segment
      errors.add :base, "cannot delete with results" if has_results?

      errors.blank?
    end
end
