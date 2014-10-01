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

class FormField::Number < FormField
  def field_options(result)
    {
      as: :string,
      label: name,
      field_id: id,
      options: settings,
      required: required,
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
    number_with_delimiter(result.value || 0)
  end

  def is_numeric?
    true
  end
end
