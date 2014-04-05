class SummationInput < SimpleForm::Inputs::Base
  def input
    output_html = ''
    total = 0
    values = object.send(attribute_name)
    group = "#{object_name}_#{attribute_name}".gsub(/[\[\]]+\z/,'').gsub(/[\[\]]+/,'_').gsub(/_+/,'_')
    options[:collection].each do |ffo|
      field_name = "#{object_name}[#{attribute_name}][#{ffo.id}]"
      field_id = "#{group}_#{ffo.id}"
      value = values.try(:[], ffo.id.to_s)
      output_html << '<div class="field-option">'+
                     "<label for=\"#{field_id}\" class=\"control-label\">#{ERB::Util.html_escape(ffo.name)} #{@builder.text_field(nil, input_html_options.merge(name: field_name, id: field_id, value: value, 'data-group' => group))}" +
                     "</label></div>"
      total += value.to_f
    end
    total_id = "#{object_name}_#{attribute_name}_total".gsub(/[\[\]]+\z/,'').gsub(/[\[\]]+/,'_').gsub(/_+/,'_')
    output_html << '<div class="field-option summation-total-field">'+
                     "<label for=\"#{total_id}\">TOTAL: #{@builder.text_field(nil, input_html_options.merge(name: 'total', id: total_id, value: total, 'data-group' => group, readonly: true))}" +
                     "</label></div>"
    output_html.html_safe
  end
end