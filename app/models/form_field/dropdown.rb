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

class FormField::Dropdown < FormField
  def field_options(result)
    { as: :select,
      collection: options_for_input,
      label: name,
      field_id: id,
      options: settings,
      required: required,
      input_html: {
        value: result.value,
        class: field_classes.push('chosen-enabled'),
        multiple: multiple?, required: (self.required? ? 'required' : nil) } }
  end

  def store_value(value)
    if value.is_a?(Array)
      value.reject(&:empty?).join(',')
    else
      value
    end
  end

  def multiple?
    settings.present? && settings.key?('multiple') && settings['multiple']
  end

  def is_optionable?
    true
  end

  def format_html(result)
    unless result.value.nil? || result.value.empty?
      options_for_input.find(-> { [] }) { |option| option[1] == result.value.to_i }[0]
    end
  end

  def format_csv(result)
    unless result.value.nil? || result.value.empty?
      options_for_input.find(-> { [] }) { |option| option[1] == result.value.to_i }[0]
    end
  end
end
