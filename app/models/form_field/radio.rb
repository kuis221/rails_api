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

class FormField::Radio < FormField
  def field_options(result)
    {
      as: :radio_buttons,
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

  def is_optionable?
    true
  end

  def format_html(result)
    unless result.value.nil? || result.value.empty?
      options_for_input.select { |option| option[1] == result.value.to_i }.map { |option| option[0] }.join(', ')
    end
  end

  def format_csv(result)
    unless result.value.nil? || result.value.empty?
      options_for_input.find(-> { [] }) { |option| option[1] == result.value.to_i }[0]
    end
  end

  def format_json(result)
    super.merge(
      value: result ? result.value || [] : nil,
      segments: options_for_input.map do |s|
        { id: s[1],
          text: s[0],
          value: result ? result.value.to_i.eql?(s[1]) : false }
      end
    )
  end

  def validate_result(result)
    super
    unless result.errors.get(:value) || result.value.nil? || result.value == ''
      unless valid_hash_keys.map(&:to_s).include?(result.value.to_s)
        result.errors.add :value, :invalid
      end
    end
  end

  def grouped_results(campaign, scope)
    form_field_results.for_event_campaign(campaign).merge(scope).group(:value).count
  end
end
