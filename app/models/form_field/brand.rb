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

class FormField::Brand < FormField
  def field_options(result)
    brands = options_for_field(result)
    selected = brands.count == 1 ? brands.first.id : result.value
    { as: :select,
      collection: brands,
      selected: selected,
      include_blank: true,
      label: self.name,
      field_id: self.id,
      options: self.settings,
      required: self.required,
      input_html: {
        value: result.value,
        class: field_classes.push('chosen-enabled form-field-brand'),
        required: (self.required? ? 'required' : nil)
      }
    }
  end

  def format_html(result)
    unless result.value.nil? || (result.value.is_a?(Array) && result.value.empty?) || result.value== ''
      ::Brand.where(id: result.value).pluck(:name).join(', ')
    end
  end

  def store_value(value)
    if value.is_a?(Array)
      value.join(',')
    else
      value
    end
  end

  def options_for_field(result)
    result.resultable.present? && result.resultable.campaign ? result.resultable.campaign.brands : ::Company.current.brands
  end
end
