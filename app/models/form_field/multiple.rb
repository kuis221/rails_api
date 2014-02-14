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
#

class FormField::Multiple < FormField
  def field_options(result)
    {as: :select, collection: self.options.order(:ordering), label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: 'activity-' + self.name.downcase + '-list', multiple: true, required: (self.required? ? 'required' : nil)}}
  end

  def store_value(value)
    if value.is_a?(Array)
      value.reject(&:empty?).join(',')
    else
      value
    end
  end
end
