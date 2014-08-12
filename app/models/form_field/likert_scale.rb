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

class FormField::LikertScale < FormField
  def field_options(result)
    {
      as: :likert_scale,
      label_html: { class: 'control-group-label' },
      collection: self.options.order(:ordering),
      statements: self.statements.order(:ordering),
      label: self.name,
      field_id: self.id,
      options: self.settings,
      required: self.required,
      input_html: {
          value: result.value,
          class: field_classes,
          min: 0,
          step: 'any',
          required: (self.required? ? 'required' : nil) } }
  end

  def field_classes
    []
  end

  def is_hashed_value?
    true
  end

  def is_optionable?
    true
  end

  def format_html(result)
    if result.value
      statements.map do |statement|
        "<span>#{options.detect{|option| option.id.to_s == result.value[statement.id.to_s] }.try(:name)}</span> #{statement.name}"
      end.join('<br /> ').html_safe
    end
  end

  protected
    def valid_hash_keys
      statements.pluck('id')
    end

    def is_valid_value_for_key?(key, value)
      @_option_ids = options.pluck('id')
      value_is_numeric?(value) && @_option_ids.include?(value.to_i)
    end
end
