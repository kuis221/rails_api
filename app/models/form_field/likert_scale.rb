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

class FormField::LikertScale < FormField::Hashed
  def field_options(result)
    {
      as: :likert_scale,
      label_html: { class: 'control-group-label' },
      collection: options.order(:ordering),
      statements: statements.order(:ordering),
      label: name,
      field_id: id,
      options: settings,
      multiple: multiple,
      have_results: form_field_results?,
      required: required,
      input_html: {
        value: result.value,
        class: field_classes,
        min: 0,
        step: 'any',
        required: (self.required? ? 'required' : nil) } }
  end

  def field_classes
    []
  end

  def is_hashed_value?
    true
  end

  def is_optionable?
    true
  end

  def format_html(result)
    return unless result.value
    statements.map do |statement|
      "<span>#{options.find { |option| option.id.to_s == result.value[statement.id.to_s] }.try(:name)}</span> #{statement.name}"
    end.join('<br /> ').html_safe
  end

  def format_json(result)
    super.merge(
      statements: statements.order(:ordering).map do |s|
        { id: s.id, text: s.name,
          value: result ? result.value[s.id.to_s] : nil }
      end,
      segments: options_for_input.map { |s| { id: s[1], text: s[0] } },
      multiple: multiple
    )
  end

  def grouped_results(campaign, _event_scope)
    events = form_field_results.for_event_campaign(campaign)
    result = events.map(&:hash_value).compact
    return [] if result.blank?

    totals = initialize_totals_likert_scale

    result.each do |value|
      value.map do |(k, v)|
        totals[k.to_i][:totals][v.to_i][:total] += 1
      end
    end
    totals.map do |(key, statement)|
      [key, statement[:name], totals_likert_scale(statement[:totals])]
    end
  end

  def csv_results(campaign, event_scope, hash_result)
    events = form_field_results.for_event_campaign(campaign).merge(event_scope)
    statements.each do |statement|
      hash_result[:titles] << "#{name} - #{statement.name}"
    end
    events.each do |event|
      value = event.hash_value.nil? ? '' : event.hash_value
      hash_result[event.resultable_id].concat(values_by_option(value)) unless hash_result[event.resultable_id].nil?
    end
    hash_result
  end

  protected

  def valid_hash_keys
    statements.pluck('id')
  end

  def is_valid_value_for_key?(_key, value)
    @_option_ids = options.pluck('id')
    value = eval(value)
    if value.is_a?(Array)
      value.each { |x| value_is_numeric?(x) } && value.each { |x| @_option_ids.include?(x.to_i) }
    else
      value_is_numeric?(value) && @_option_ids.include?(value.to_i)
    end
  end

  def initialize_totals_likert_scale
    statements.reduce({}) do |memo, (statement)|
      memo[statement.id] = {
        name: statement.name,
        totals: options.reduce({}) do |m, (option)|
          m[option.id] = { name: option.name, total: 0 }
          m
        end
      }
      memo
    end
  end

  def totals_likert_scale(totals)
    values = totals.reject { |_, v| v[:total].nil? || v[:total] == '' || v[:total].to_f == 0.0 }
    values.map { |_, v| [v[:name], v[:total]] }
  end

  def values_by_option(hash_values)
    statements.reduce([]) do |memo, statement|
      opt = hash_values[statement.id.to_s]
      object_option = options.find(opt.to_i) unless opt.nil?
      value = object_option.nil? ? '' : object_option.name
      memo << value
      memo
    end
  end
end
