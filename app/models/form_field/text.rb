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

class FormField::Text < FormField
  def field_options(result)
    {
      as: :string,
      label: self.name,
      field_id: self.id,
      options: self.settings,
      required: self.required,
      input_html: {
        value: result.value,
        class: field_classes.push('elements-range'),
        data: field_data,
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
    unless result.errors.get(:value) || !result.value.is_a?(String) || result.value.blank?
      val = result.value.strip
      if self.settings['range_format'] == 'characters'
        items = val.length
      else
        items = val.scan(/\w+/).size
      end

      min_result = self.settings['range_min'].present? ? items >= self.settings['range_min'].to_i : true
      max_result = self.settings['range_max'].present? ? items <= self.settings['range_max'].to_i : true

      if !min_result || !max_result
        result.errors.add :value, :invalid
      end
    end
  end
end
