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

class FormField::Time < FormField
  def field_options(result)
    {as: :time_picker, label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: field_classes, step: 'any', required: (self.required? ? 'required' : nil)}}
  end

  def field_classes
    ['field-type-time']
  end

  def format_html(result)
    Timeliness.parse(result.value).strftime('%H:%M <i>%p</i>').html_safe rescue nil  if result.value
  end
end
