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

class FormField::Marque < FormField::Dropdown
  def field_options(result)
    marques = []
    if result.id
      ff_brand_id = FormField.where(type: 'FormField::Brand', fieldable_id: result.activity.activity_type.id).first.id
      brand_id = ActivityResult.where(activity_id: result.activity_id, form_field_id: ff_brand_id).first.value
      marques = ::Marque.where(brand_id: brand_id)
    end
    {as: :select, collection: marques, label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: 'activity-' + self.name.downcase + '-list', multiple: self.multiple?, required: (self.required? ? 'required' : nil)}}
  end
end
