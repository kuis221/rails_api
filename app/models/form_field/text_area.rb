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

class FormField::TextArea < FormField
  def field_options(result)
    {
      as: :text,
      label: name,
      field_id: id,
      options: settings,
      required: required,
      input_html: {
        value: result.value,
        class: field_classes,
        data: field_data,
        required: (self.required? ? 'required' : nil)
      }
    }
  end

  def field_classes
    ['elements-range']
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

  def format_html(result)
    result.value.gsub(/\n/, '<br>').html_safe unless result.value.nil?
  end
end
