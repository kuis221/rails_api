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

class FormField::Checkbox < FormField
  def field_options(result)
    {
      as: :check_boxes,
      collection: options_for_input,
      label: self.name,
      field_id: self.id,
      options: self.settings,
      required: self.required,
      label_html: { class: 'control-group-label' },
      input_html: {
        value: result.value,
        required: (self.required? ? 'required' : nil) } }
  end

  def format_html(result)
    unless result.value.nil? || result.value.empty?
      selected = result.value.map(&:to_i)
      options_for_input.select{|r| selected.include?(r[1].to_i) }.map do |v|
        "<span>#{v[0]}</span>"
      end.join.html_safe
    end
  end

  def is_hashed_value?
    true
  end

  def is_optionable?
    true
  end

  def store_value(values)
    if values.is_a?(Hash)
      values
    elsif values.is_a?(Array)
      Hash[values.reject{|v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }.map{|v| [v, 1] }]
    else
      {values => nil}
    end
  end

  def validate_result(result)
    if required? && (result.hash_value.nil? || result.hash_value.keys.empty?)
      result.errors.add(:value, I18n.translate('errors.messages.blank'))
    elsif result.hash_value.present?
      if result.hash_value.any?{|k, v| v != '' && !is_valid_value_for_key?(k, v) }
        result.errors.add :value, :invalid
      elsif (result.hash_value.keys.map(&:to_s) - valid_hash_keys.map(&:to_s)).any?
        result.errors.add :value, :invalid  # If a invalid key was given
      end
    end
  end
end
