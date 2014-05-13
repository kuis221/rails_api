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

class FormField::Number < FormField
  def field_options(result)
    {as: :decimal, label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, class: field_classes, step: 'any', required: (self.required? ? 'required' : nil)}}
  end

  def validate_result(result)
    super
    if result.value.present?
      result.errors.add:value, I18n.translate('errors.messages.not_a_number') if !parse_raw_value_as_a_number(result.value)
    end
  end

  def is_numeric?
    true
  end

  protected
    def parse_raw_value_as_a_number(raw_value)
      Kernel.Float(raw_value) if raw_value !~ /\A0[xX]/
    rescue ArgumentError, TypeError
      nil
    end
end
