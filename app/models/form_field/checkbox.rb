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

class FormField::Checkbox < FormField::Hashed
  def field_options(result)
    {
      as: :check_boxes,
      collection: options_for_input,
      label: name,
      field_id: id,
      options: settings,
      required: required,
      label_html: { class: 'control-group-label' },
      input_html: {
        value: result.value,
        required: (self.required? ? 'required' : nil) } }
  end

  def format_html(result)
    unless result.value.nil? || result.value.empty?
      selected = result.value.map(&:to_i)
      options_for_input.select { |r| selected.include?(r[1].to_i) }.map do |v|
        "<span><i class=\"icon icon-checked\"></i>#{v[0]}</span>"
      end.join.html_safe
    end
  end

  def format_csv(result)
    return if result.value.nil? || result.value.empty?
    selected = result.value.map(&:to_i)
    options_for_input.select { |r| selected.include?(r[1].to_i) }.map do |v|
      v[0]
    end.join(',')
  end

  def format_json(result)
    super.merge!(
      value: result ? result.value || [] : nil,
      segments: options_for_input.map do |s|
                  { id: s[1],
                    text: s[0],
                    value: result ? result.value.include?(s[1]) : false }
                end
    )
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
      Hash[values.reject { |v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }.map { |v| [v, 1] }]
    else
      { values => nil }
    end
  end

  def validate_result(result)
    if required? && (result.hash_value.nil? || result.hash_value.keys.empty?)
      result.errors.add(:value, I18n.translate('errors.messages.blank'))
    elsif result.hash_value.present?
      if result.hash_value.any? { |k, v| v != '' && !is_valid_value_for_key?(k, v) }
        result.errors.add :value, :invalid
      elsif (result.hash_value.keys.map(&:to_s) - valid_hash_keys.map(&:to_s)).any?
        result.errors.add :value, :invalid  # If a invalid key was given
      end
    end
  end

  def grouped_results(campaign, event_scope)
    result = form_field_results.for_event_campaign(campaign).merge(event_scope)
                                .pluck('hash_value')
                                .select { |h| h unless h.blank? }
    results_for_percentage_chart_for_hash(result)
  end
end
