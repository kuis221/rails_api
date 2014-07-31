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
    {as: :currency, label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: field_classes, step: 'any', required: (self.required? ? 'required' : nil)}}
  end

  def format_html(result)
    number_to_currency(result.value || 0, precision: 2)
  end

  def is_numeric?
    true
  end
end
