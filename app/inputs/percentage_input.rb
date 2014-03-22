class PercentageInput < SimpleForm::Inputs::Base
  def input
    if options[:collection] && options[:collection].length > 0
      output_html = ''
      options[:collection].each do |ffo|
        field_name = "#{object_name}[#{attribute_name}][#{ffo.id}]"
        field_id = field_name.gsub(/[\[\]]+\z/,'').gsub(/[\[\]]+/,'_')
        output_html << "<div class=\"input-append\">#{@builder.text_field(nil, input_html_options.merge(name: field_name, id: field_id))}<span class=\"add-on\">%</span></div>"
      end
      output_html.html_safe
    else
      "<div class=\"input-append\">#{@builder.text_field(attribute_name, input_html_options)}<span class=\"add-on\">%</span></div>".html_safe
    end
  end
end