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

class FormField::Percentage < FormField
  def field_options(result)
    {
      as: :percentage,
      collection: options_for_input,
      label: self.name,
      field_id: self.id,
      options: self.settings,
      required: self.required,
      label_html: { class: 'control-group-label' },
      input_html: {
        value: result.value,
        class: field_classes,
        min: 0,
        step: 'any',
        required: (self.required? ? 'required' : nil)
      }
    }
  end

  def field_classes
    [:number, 'segment-field']
  end

  def is_hashed_value?
    true
  end

  def is_optionable?
    true
  end

  def format_html(result)
    if result.value
      options.map do |option|
        "#{option.name}: #{result.value[option.id.to_s] || 0}%"
      end.join('<br />').html_safe
    end
  end

  def validate_result(result)
    super
    if result.value.present?
      if result.value.is_a?(Hash)
        if (result.value.keys.map(&:to_i) - options_for_input.map{|o| o[1]}).any?
          result.errors.add :value, :invalid  # If a invalid key was given
        elsif result.value.values.map(&:to_f).reduce(:+).to_i != 100
          result.errors.add :value, :invalid
        end
      else
        result.errors.add :value, :invalid
      end
    end
  end
end
