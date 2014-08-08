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
include ActionView::Helpers::NumberHelper

class FormField::Currency < FormField
  def field_options(result)
    {
      as: :currency,
      label: self.name,
      field_id: self.id,
      options: self.settings,
      required: self.required,
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
    if self.settings.present?
      data['range-format'] = self.settings['range_format'] if self.settings['range_format'].present?
      data['range-min'] = self.settings['range_min'] if self.settings['range_min'].present?
      data['range-max'] = self.settings['range_max'] if self.settings['range_max'].present?
    end
    data
  end

  def validate_result(result)
    super
    if result.value.present?
      result.errors.add:value, I18n.translate('errors.messages.not_a_number') if !value_is_numeric?(result.value)
    end
  end

  def format_html(result)
    number_to_currency(result.value || 0, precision: 2)
  end

  def is_numeric?
    true
  end
end
