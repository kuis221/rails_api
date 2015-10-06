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
#  multiple       :boolean
#

class FormField::Dropdown < FormField::Hashed
  def field_options(result)
    { as: :select,
      collection: options_for_input,
      label: name,
      field_id: id,
      options: settings,
      required: required,
      input_html: {
        value: result.value.to_i,
        class: field_classes.push('chosen-enabled'),
        multiple: multiple?, required: (self.required? ? 'required' : nil) } }
  end

  def store_value(value)
    if value.is_a?(Array)
      value.reject(&:empty?).join(',')
    else
      value
    end
  end

  def multiple?
    settings.present? && settings.key?('multiple') && settings['multiple']
  end

  def is_optionable?
    true
  end

  def format_html(result)
    return if result.value.nil? || result.value.empty?
    options_for_input.find(-> { [] }) { |option| option[1] == result.value.to_i }[0]
  end

  def format_csv(result)
    return if result.value.nil? || result.value.empty?
    options_for_input.find(-> { [] }) { |option| option[1] == result.value.to_i }[0]
  end

  def format_json(result)
    super.merge(
      value: result ? result.value || [] : nil,
      segments: options_for_input.map do |s|
        { id: s[1],
          text: s[0],
          value: result ? result.value.to_i.eql?(s[1]) : false }
      end
    )
  end

  def grouped_results(campaign, event_scope)
    result = form_field_results.for_event_campaign(campaign).merge(event_scope).group(:value).count
    results_for_percentage_chart_for_value(result)
  end

  def csv_results(campaign, event_scope, hash_result)
    events = form_field_results.for_event_campaign(campaign).merge(event_scope)
    hash_result[:titles] << name

    events.each do |event|
      options_map = Hash[options_for_input.map { |o| [o[1], o[0]] }]
      value = event.value.nil? ? '' : options_map[event.value.to_i]
      hash_result[event.resultable_id] << value
    end
    hash_result
  end
end
