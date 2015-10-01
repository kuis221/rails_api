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

include ActionView::Helpers::NumberHelper

class FormField::Currency < FormField
  def field_options(result)
    {
      as: :currency,
      label: name,
      field_id: id,
      options: settings,
      required: required,
      hint: range_message,
      hint_html: {
        id: "hint-#{id}",
        class: 'range-help-block'
      },
      input_html: {
        value: result.value,
        class: field_classes.push('elements-range'),
        data: field_data,
        step: 'any',
        required: (self.required? ? 'required' : nil)
      }
    }
  end

  def field_data
    data = {}
    if settings.present?
      data['range-format'] = settings['range_format'] if settings['range_format'].present?
      data['range-min'] = settings['range_min'] if settings['range_min'].present?
      data['range-max'] = settings['range_max'] if settings['range_max'].present?
      data['field-id'] = id
    end
    data
  end

  def validate_result(result)
    super
    if result.value.present?
      result.errors.add :value, I18n.translate('errors.messages.not_a_number') unless value_is_numeric?(result.value)
    end
  end

  def format_html(result)
    number_to_currency(result.value || 0, precision: 2)
  end

  def is_numeric?
    true
  end

  def grouped_results(campaign, event_scope)
    events = form_field_results.for_event_campaign(campaign).merge(event_scope)
    result = events.map { |event| event.value }
    total = result.compact.inject{ |sum,x| sum.to_f + x.to_f } || 0
    "$#{total}"
  end

  def csv_results(campaign, event_scope, hash_result)
    events = form_field_results.for_event_campaign(campaign).merge(event_scope)
    hash_result[:titles] << name
    events.each do |event|
      value = event.value.nil? ? "" : event.value
      hash_result[event.resultable_id] << value unless hash_result[event.resultable_id].nil?
    end
    hash_result
  end
end
