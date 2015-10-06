class CountInput < SimpleForm::Inputs::Base
  def input(_wrapper_options)
    if options[:capture_mechanism] == 'radio'
      "#{@builder.radio_button(attribute_name, options[:field_id], input_html_options)}".html_safe
    else
      "#{@builder.text_field(attribute_name, input_html_options)}".html_safe
    end
  end
end
