# == Schema Information
#
# Table name: metrics
#
#  id          :integer          not null, primary key
#  type        :string(32)
#  brand_id    :integer
#  program_id  :integer
#  name        :string(255)
#  style       :string(255)
#  optional_id :integer
#  active      :boolean          default(TRUE)
#  creator_id  :integer
#  updater_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#

# INTERNAL USE - stores data in EventRecap
# positive whole number representing event count.
# autopopulates with 1
require 'legacy/metric/whole'
class Metric::NumberOfEvents < Metric::Whole
  validates_presence_of :program_id, message: 'must be a program metric'
  validates_uniqueness_of :type, scope: :program_id

  def form_options
    super.merge(hint: 'Whole numbers, no decimals')
  end

  def field_type_symbol
    '!NE'
  end

  def validate_result(result)
    super
    result.errors.add(:value, 'must be positive') if result.errors.empty? && cast_value(result.value) < 0
  end

  def store_result(value, result)
    super # call super to ALSO store the data in the result - TODO does this make sense?
    result.event_recap.update_attribute(:number_of_events, cast_value(value)) if result.event_recap
  end

  def fetch_result(result)
    result.event_recap.number_of_events if result.event_recap
  end
end
