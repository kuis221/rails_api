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

class FormField::LikertScale < FormField
  def field_options(result)
    {
      as: :likert_scale,
      label_html: { class: 'control-group-label' },
      collection: options.order(:ordering),
      statements: statements.order(:ordering),
      label: name,
      field_id: id,
      options: settings,
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
      segments: options_for_input.map { |s| { id: s[1], text: s[0] } }
    )
  end

  def grouped_results(campaign, event_scope)
    result = form_field_results.for_event_campaign(campaign).pluck('hash_value').select { |h| h unless h.blank? }
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

  protected

  def valid_hash_keys
    statements.pluck('id')
  end

  def is_valid_value_for_key?(_key, value)
    @_option_ids = options.pluck('id')
    value_is_numeric?(value) && @_option_ids.include?(value.to_i)
  end

  def initialize_totals_likert_scale
    statements.inject({}) do |memo, (statement)|
      memo[statement.id] = {
        name: statement.name,
        totals: options.inject({}) do |m, (option)|
            m[option.id] = { name: option.name, total: 0 }
            m
        end
      }
      memo
    end
  end

  def totals_likert_scale(totals)
    values = totals.reject{ |_, v| v[:total].nil? || v[:total] == '' || v[:total].to_f == 0.0 }
    values.map{ |_, v| [v[:name], v[:total]] }
  end
end
