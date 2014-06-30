class PercentageInput < SimpleForm::Inputs::Base
  def input
    if options[:collection] && options[:collection].length > 0
      output_html = ''
      values = object.send(attribute_name)
      options[:collection].each do |ffo|
        field_name = "#{object_name}[#{attribute_name}][#{ffo[1]}]"
        field_id = field_name.gsub(/[\[\]]+\z/,'').gsub(/[\[\]]+/,'_')
        output_html << "<div class=\"input-append\">#{@builder.text_field(nil, input_html_options.merge(name: field_name, id: field_id, value: values.try(:[], ffo[1].to_s)))}<span class=\"add-on\">%</span></div>" +
                       "<label for=\"#{field_id}\">#{ERB::Util.html_escape(ffo[0])}</label>"
      end
      output_html.html_safe
    else
      "<div class=\"input-append\">#{@builder.text_field(attribute_name, input_html_options)}<span class=\"add-on\">%</span></div>".html_safe
    end
  end
end