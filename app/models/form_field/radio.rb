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

class FormField::Radio < FormField
  has_many :options, class_name: 'FormFieldOption', dependent: :destroy, inverse_of: :form_field, foreign_key: :form_field_id

  def field_options(result)
    {as: :radio_buttons, collection: self.options.order(:ordering), label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, required: (self.required? ? 'required' : nil)}}
  end

  def format_html(result)
    unless result.value.nil? || result.value.empty?
      self.options.where(id: result.value).pluck(:name).join(', ')
    end
  end
end
