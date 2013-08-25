class PercentageInput < SimpleForm::Inputs::Base
  def input
    "<div class=\"input-append\">#{@builder.text_field(attribute_name, input_html_options)}<span class=\"add-on\">%</span></div>".html_safe
  end
end