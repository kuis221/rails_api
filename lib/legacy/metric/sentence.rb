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

# for storing one line of text
class Metric::Sentence < Metric
  def form_options
    super.merge(as: :string)
  end
  def self.targetable?
    false
  end
  def field_type_symbol
    '...'
  end

  def store_result(value, result)
    result.vector_value = cast_value(value)
  end

  def fetch_result(result)
    cast_value result.vector_value
  end
end
