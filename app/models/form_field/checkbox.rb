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

class FormField::Checkbox < FormField
  def field_options(result)
    {as: :check_boxes, collection: self.options, label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, required: (self.required == true ? 'required' : nil)}}
  end
end
