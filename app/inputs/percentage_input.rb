class PercentageInput < SimpleForm::Inputs::Base
  def input
    if options[:collection] && options[:collection].length > 0
      field_id = options[:field_id].to_s
      output_html = '
      <div class="control-group">
        <input class="segment-total optional" id="total-field-'+field_id+'" name="total-field-'+field_id+'" type="text" value="">
        <span class="help-inline error segment-error-label" for="total-field-'+field_id+'" id="progress-error-'+field_id+'"></span>
        <div class="percentage-progress-bar text-success" id="progress-bar-field-'+field_id+'">
          <div class="progress progress-success">
            <div class="bar"></div>
          </div>
          <div class="counter"></div>
        </div>
      </div>'

      values = object.send(attribute_name)
      options[:collection].each do |ffo|
        field_name = "#{object_name}[#{attribute_name}][#{ffo[1]}]"
        field_id = field_name.gsub(/[\[\]]+\z/,'').gsub(/[\[\]]+/,'_')
        output_html << "<div class=\"control-group\">" +
            "<span for=\"#{field_id}\" class=\"help-inline\" style=\"display:none;\"></span>" +
            '<div class="clearfix"></div>' +
            "<div class=\"input-append\">#{@builder.text_field(nil, input_html_options.merge(name: field_name, id: field_id, data: {'segment-field-id' => options[:field_id]}, value: values.try(:[], ffo[1].to_s)))}"+
            "<span class=\"add-on\">%</span></div>" +
            "<label for=\"#{field_id}\" class=\"segment-label\">#{ERB::Util.html_escape(ffo[0])}</label></div>"
      end
      output_html.html_safe
    else
      "<div class=\"input-append\">#{@builder.text_field(attribute_name, input_html_options)}<span class=\"add-on\">%</span></div>".html_safe
    end
  end
end