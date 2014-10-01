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

# for storing free text
# include ActionView::Helpers::TagHelper
# include ActionView::Helpers::TextHelper
class Metric::Paragraph < Metric
  def form_options
    super.merge(as: :text)
  end

  def format_result(result)
    simple_format(result.value)
  end

  def format_pdf(pdf, result)
    pdf.text result.value.to_s if result && result.print_values?
  end

  def result_hash(result)
    { name => format_result(result) }
  end
  def self.targetable?
    false
  end
  def field_type_symbol
    '&para;'
  end

  def default_columns
    3
  end

  def default_rows
    2
  end

  def store_result(value, result)
    result.vector_value = cast_value(value)
  end

  def fetch_result(result)
    cast_value result.vector_value
  end
end
