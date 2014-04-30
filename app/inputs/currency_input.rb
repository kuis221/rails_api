class CurrencyInput < SimpleForm::Inputs::Base
  def input
    "<div class=\"input-prepend\"><span class=\"add-on\">$</span>#{@builder.number_field(attribute_name, input_html_options)}</div>".html_safe
  end
end