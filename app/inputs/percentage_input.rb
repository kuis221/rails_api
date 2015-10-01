class PercentageInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    if options[:collection] && options[:collection].length > 0
      field_id = options[:field_id].to_s
      output_html = '
      <div id="progress-for-' + field_id + '" class="control-group">
        <input class="segment-total ' + (options[:required] ? 'required' : 'optional') +'" id="total-field-' + field_id + '" name="total-field-' + field_id + '" type="text" value="" data-segment-field-id="' + field_id + '">
        <div class="clearfix"></div>
        <div class="percentage-progress-bar text-success" id="progress-bar-field-' + field_id + '">
          <div class="progress progress-success">
            <div class="bar"></div>
          </div>
          <div class="counter"></div>
        </div>
      </div>'

      values = object.send(attribute_name)
      options[:collection].each do |ffo|
        field_name = "#{object_name}[#{attribute_name}][#{ffo[1]}]"
        field_id = field_name.gsub(/[\[\]]+\z/, '').gsub(/[\[\]]+/, '_')
        output_html << "<div class=\"control-group\">" \
            "<span for=\"#{field_id}\" class=\"help-inline segment-error-" + options[:field_id].to_s + " valid\" style=\"display:none;\"></span>" \
            '<div class="clearfix"></div>' \
            "<div class=\"input-append\">#{@builder.text_field(nil, segment_input_options(field_id, field_name, values.try(:[], ffo[1].to_s)))}"\
            "<span class=\"add-on\">%</span></div>" \
            "<label for=\"#{field_id}\" class=\"segment-label\">#{ERB::Util.html_escape(ffo[0])}</label></div>"
      end
      output_html << '
      <div class="control-group">
        <span id="progress-error-' + options[:field_id].to_s + '" class="help-inline error segment-error-label" for="total-field-' + options[:field_id].to_s + '" data-segment-field-id="' + options[:field_id].to_s + '"></span>
      </div>
      <div class="clearfix"></div>'
      output_html.html_safe
    else
      "<div class=\"input-append\">#{@builder.text_field(attribute_name, input_html_options)}<span class=\"add-on\">%</span></div>".html_safe
    end
  end

  def segment_input_options(field_id, field_name, value)
    options[:segment_html].merge(
        name: field_name,
        required: false, id: field_id,
        data: { 'segment-field-id' => options[:field_id] },
        value: value)
  end
end
