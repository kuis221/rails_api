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

# For storing rational numbers with a decimal place.
class Metric::Decimal < Metric
  def format_result(result)
    number_with_delimiter(result.value)
  end
  def format_total(total)
    number_with_delimiter(total)
  end
  def field_type_symbol
    '0.0'
  end
  def validate_result(result)
    result.errors.add(:value, 'must be a number') unless value_is_float?(result.value)
  end
  def cast_value(value)
    value.to_f
  end
end
