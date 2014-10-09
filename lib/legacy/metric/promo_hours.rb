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
# positive decimal number representing promo hours.
# autopopulates with 1
require 'legacy/metric/decimal'

class Metric::PromoHours < Metric::Decimal
  validates_presence_of :program_id, message: 'must be a program metric'
  validates_uniqueness_of :type, scope: :program_id

  def field_type_symbol
    '!PH'
  end

  def validate_result(result)
    super
    result.errors.add(:value, 'must be positive') if result.errors.empty? && cast_value(result.value) < 0
  end

  def store_result(value, result)
    super # call super to ALSO store the data in the result - TODO does this make sense?
    result.event_recap.update_attribute(:promo_hours, cast_value(value)) if result.event_recap
  end

  def fetch_result(result)
    result.event_recap.promo_hours if result.event_recap
  end
end
