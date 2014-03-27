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

class FormField::Summation < FormField
  def field_options(result)
    {as: :summation, collection: self.options.order(:ordering), label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: field_classes, min: 0, step: 'any', required: (self.required? ? 'required' : nil)}}
  end

  def field_classes
    [:number]
  end

  def is_hashed_value?
    true
  end
end