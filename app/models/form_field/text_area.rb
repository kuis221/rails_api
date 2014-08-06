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
      label: self.name,
      field_id: self.id,
      options: self.settings,
      required: self.required,
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
    if self.settings.present?
      data['range-format'] = self.settings['range_format'] if self.settings['range_format'].present?
      data['range-min'] = self.settings['range_min'] if self.settings['range_min'].present?
      data['range-max'] = self.settings['range_max'] if self.settings['range_max'].present?
    end
    data
  end

  def format_html(result)
    result.value.gsub(/\n/, '<br>').html_safe unless result.value.nil?
  end
end
