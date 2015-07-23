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

class FormField::Summation < FormField::Hashed
  MIN_OPTIONS_ALLOWED = 2
  def field_options(result)
    {
      as: :summation,
      collection: options.order(:ordering),
      label: name, field_id: id,
      label_html: { class: 'control-group-label' },
      options: settings,
      required: required,
      input_html: {
        value: result.value,
        class: field_classes,
        min: 0,
        step: 'any',
        required: (self.required? ? 'required' : nil) } }
  end

  def field_classes
    [:number]
  end

  def is_hashed_value?
    true
  end

  def is_optionable?
    true
  end

  def format_html(result)
    return unless result.value
    total = 0
    (options.map do |option|
      total += (result.value[option.id.to_s].to_i || 0)
      "<span>#{result.value[option.id.to_s] || 0}</span> #{option.name}"
    end.join('<br /> ') +
    "<br/><span>#{total}</span> TOTAL"
    ).html_safe
  end

  def format_json(result)
    super.merge(
      value: result ? result.value.map { |s| s[1].to_f }.reduce(0, :+) : nil,
      segments: options_for_input(result).map do |s|
        { id: s[1],
          text: s[0],
          value: result ? result.value[s[1].to_s] : nil }
      end
    )
  end

  def min_options_allowed
    MIN_OPTIONS_ALLOWED
  end

  def grouped_results(campaign, event_scope)
    result = form_field_results.for_event_campaign(campaign).merge(event_scope)
                                .pluck('hash_value')
                                .select { |h| h unless h.blank? }
    results_for_hash_values(result)
  end
end
