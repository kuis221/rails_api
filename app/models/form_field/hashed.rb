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

  def csv_results(campaign, event_scope, hash_result)
    events = form_field_results.for_event_campaign(campaign).merge(event_scope)
    options_for_input.each do |n,_|
      hash_result[:titles] << "#{name} - #{n}"
    end
    events.each do |event|
      value = event.hash_value.nil? ? "" : event.hash_value
      hash_result[event.resultable_id].concat(values_by_option(value)) unless hash_result[event.resultable_id].nil?
    end
    hash_result
  end

  def values_by_option(hash_values)
    options_for_input.inject([]) do |memo, option|
      memo << hash_values[option[1].to_s]
      memo
    end
  end
end