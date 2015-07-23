# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  kpi_id         :integer
#

class FormField::Hashed < FormField
  def results_for_hash_values(result)
    return [] if result.blank?

    keys = options_for_input.map { |k, v| v.to_s }
    totals = Hash[keys.zip(result.map { |h| h.values_at(*keys) }.inject{ |a, v| a.zip(v).map{ |sum, t| sum.to_f + t.to_f} })]

    totals.inject({}) do |memo, (key, value)|
      memo[key.to_i] = value
      memo
    end
  end

  def results_for_percentage_chart_for_hash(result)
    totals = results_for_hash_values(result)

    values = totals.reject{ |k, v| v.nil? || v == '' || v.to_f == 0.0 }
    options_map = Hash[options_for_input.map{|o| [o[1], o[0]] }]
    values.map{ |k, v| [options_map[k], v] }
  end

  def results_for_percentage_chart_for_value(result)
    values = result.reject{ |k, v| k == nil || v.nil? || v == '' || v.to_f == 0.0 }
    options_map = Hash[options_for_input.map{|o| [o[1], o[0]] }]
    values.map{ |k, v| [options_map[k.to_i], v] }
  end

  def percent_of(n, t)
    n.to_f / t.to_f * 100.0
  end
end