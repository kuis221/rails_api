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
      ff_brand = FormField.where(type: 'FormField::Brand', fieldable_id: fieldable_id, fieldable_type: fieldable_type)
      if ff_brand.present?
        brand = ActivityResult.where(activity_id: result.activity_id, form_field_id: ff_brand.first.id)
        if brand.present?
          marques = ::Marque.where(brand_id: brand.first.value)
        end
      end
    end
    {as: :select, collection: marques, label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: 'form-field-marque', multiple: self.multiple?, required: (self.required? ? 'required' : nil)}}
  end
end

def format_html
  "Marque <br>".html_safe
end