class CalculationInput < SimpleForm::Inputs::Base
  OPERATOR_CLASSES = {
    '*' => 'multiply',
    '/' => 'divide',
    '-' => 'subtract',
    '+' => 'add'
  }

  def label(wrapper_options)
    super  +
      ('<div class="control-group inline-block">'\
       "<span for=\"total-field-#{options[:field_id]}\" class=\"help-inline\" ></span>"\
       '<input class="calculation-total calculation-field-' + operator_class(options[:operation]) + '" '\
                         'id="total-field-' + field_id + '" '\
                         'name="total-field-' + field_id + '" type="text" value="" data-group="' + group_name + '">'\
       '</div>').html_safe
  end

  def input(_wrapper_options)
    total = 0
    values = object.send(attribute_name)
    output_html = '<table class="calculation-field" data-operation="' + options[:operation] + '"><tbody>'
    options[:collection].each_with_index do |ffo, i|
      field_name = "#{object_name}[#{attribute_name}][#{ffo.id}]"
      option_id = "#{group_name}_#{ffo.id}"
      value = values.try(:[], ffo.id.to_s)
      output_html << '<tr class="field-option control-group" data-field-id="' + field_id + '">'
      extra_attributes = i > 0 ? "class=\"operation #{operator_class(options[:operation])}\"" : ''
      output_html << "<td #{extra_attributes}>"
      output_html << "<label for=\"#{option_id}\" class=\"control-label\">#{ERB::Util.html_escape(ffo.name)}</label>"
      #output_html << "<span for=\"#{option_id}\" class=\"help-inline\" style=\"display:none;\"></span>"
      output_html << '<td>'
      output_html << @builder.text_field(nil, input_html_options.merge(name: field_name, id: option_id,
                                                                       class: 'calculation-field number calculation-field-segment-' + operator_class(options[:operation]), value: value,
                                                                       required: false, 'data-group' => group_name, 'data-index' => i))
      output_html << '</td></tr>'
      total += value.to_f
    end
    total_id = "#{object_name}_#{attribute_name}_total".gsub(/[\[\]]+\z/, '').gsub(/[\[\]]+/, '_').gsub(/_+/, '_')
    output_html << '<tr class="field-option calculation-total-field" data-field-id="' + field_id + '"><td colspan="2" class="text-right"><div>'
    output_html << "<label class=\"calculation\" for=\"#{total_id}\">#{options[:calculation_label]}: </label>"
    output_html << "<span class=\"calculation-total-amount\" data-group=\"#{group_name}\">#{total}</span>"
    output_html << '</div></td></tr></tbody></table>'
    output_html.html_safe
  end

  def group_name
    @group_name ||= "#{object_name}_#{attribute_name}"
                      .gsub(/[\[\]]+\z/, '').gsub(/[\[\]]+/, '_').gsub(/_+/, '_')
  end

  def field_id
    @field_id ||= options[:field_id].to_s
  end

  def operator_class(operation)
    OPERATOR_CLASSES[operation]
  end
end
