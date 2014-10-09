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

class Metric::Tab < Metric
  TAB   = 0 # ew. constants :(
  TIP   = 1
  TOTAL = 2

  def format_result(result)
    value = cast_value(result.value)
    "tab #{ActionController::Base.helpers.number_to_currency value[TAB]} + tip #{ActionController::Base.helpers.number_to_currency value[TIP]} = #{ActionController::Base.helpers.number_to_currency value[TAB] + value[TIP]}"
  end

  def format_total(total)
    number_to_currency(total)
  end

  def format_pdf(pdf, result)
    w = pdf.bounds.width.to_i
    h = pdf.cursor.to_i

    if result && result.print_values?
      super
    else
      table_data = [['Tab', '$', ' ', '+', 'Tip', '$', ' ', '=', '$', ' ']]
      pdf.table table_data, width: w, column_widths: { 2 => w / 6, 6 => w / 6, 9 => w / 6 } do
        cells.style(overflow: :shrink_to_fit, borders: [], padding: 0)
        [2, 6, 9].each do |i|
          columns(i).style(align: :left, borders: [:bottom])
        end
      end
    end
  end

  def field_type_symbol
    '$+$'
  end

  def default_columns
    2
  end

  def validate_result(result)
    values = Metric.scrub_hash_keys(result.value)
    if value_is_float?(values[TAB])
      result.errors.add(:values, 'tab cannot be negative') if values[TAB].to_f < 0
    else
      result.errors.add(:values, 'tab must be a number')
    end

    if value_is_float?(values[TIP])
      result.errors.add(:values, 'tip cannot be negative') if values[TIP].to_f < 0
    else
      result.errors.add(:values, 'tip must be a number')
    end
  end

  def cast_value(value)
    v = Metric.scrub_hash_keys(value)
    v = { TAB => v[TAB].to_f, TIP => v[TIP].to_f }
    v[TOTAL] = v[TAB] + v[TIP]
    v
  end

  def store_result(value, result)
    v = cast_value(value)
    result.scalar_value = v[TOTAL]
    result.vector_value = cast_value(value)
  end

  def fetch_result(result)
    cast_value result.vector_value
  end
end
