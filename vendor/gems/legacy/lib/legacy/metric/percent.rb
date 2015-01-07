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

# For storing percents. May get turned into percent group later.
class Metric::Percent < Metric
  def form_options
    super.merge(hint: 'A percentage value between 0 and 100', input_html: { min: 0, max: 100 })
  end

  def format_result(result)
    number_to_percentage(result.to_f, precision: 2)
  end

  def format_total(total)
    number_to_percentage(total.to_f, precision: 2)
  end

  def format_pdf(pdf, result)
    if result && result.print_values?
      super
    else
      pdf.font_size(10) { pdf.text '%', align: :left, valign: :center }
    end
  end

  def field_type_symbol
    '%'
  end

  def validate_result(result)
    result.errors.add(:values, 'must be a number') unless value_is_float?(result.value)
    result.errors.add(:value, 'cannot be negative') if cast_value(result.value) < 0
    result.errors.add(:value, 'cannot be over 100%') if cast_value(result.value) > 100
  end

  def cast_value(value)
    value.to_i
  end
end
