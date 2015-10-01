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
#  multiple       :boolean
#

class FormField::Marque < FormField::Dropdown
  def field_options(result)
    {
      as: :select,
      collection: options_for_field(result),
      label: name,
      field_id: id,
      options: settings,
      required: required,
      input_html: {
        value: result.value,
        class: field_classes.push('chosen-enabled form-field-marque'),
        multiple: self.multiple?,
        required: (self.required? ? 'required' : nil)
      }
    }
  end

  def is_optionable?
    true
  end

  def format_html(result)
    return if result.value.blank? || result.value == 0
    ::Marque.where(id: result.value).pluck(:name).join(', ')
  end

  def format_csv(result)
    format_html result
  end

  def format_json(result)
    super.merge(
      value: result ? result.value.to_i : nil,
      segments: options_for_field(result).map do |s|
        { id: s[1],
          text: s[0],
          value: result ? result.value.to_i.eql?(s[1]) : false }
      end
    )
  end

  def options_for_field(result)
    return [] if result.nil?
    @marques ||= [].tap do |b|
      ff_brand  = FormField.where(fieldable_id: fieldable_id,
                                  fieldable_type: fieldable_type,
                                  type: 'FormField::Brand').first
      return [] unless ff_brand.present?

      brand_id = find_brand_id_for_result(result, ff_brand)
      b.concat ::Marque.where(brand_id: brand_id).pluck(:name, :id) if brand_id.present?
    end
  end

  def find_brand_id_for_result(result, ff_brand)
    if result.id
      results = result.resultable.results_for([ff_brand])
      return results.first.value if results.any?
    end
    return unless result.resultable.respond_to?(:campaign) && result.resultable.campaign
    ids = result.resultable.campaign.brand_ids
    ids.first if ids.count == 1
  end
end
