class LocationInput < SimpleForm::Inputs::Base
  def input
    (@builder.hidden_field(attribute_name, input_html_options) + ' ' + @builder.text_field(nil, {:name => "#{attribute_name.to_s}_display_name", :id => attribute_name.to_s+'_ac', 'data-hidden' => "##{input_class}", :value => input_html_options[:display_value], :class => "places-autocomplete #{input_html_options[:class].join(' ')}", :placeholder => 'Enter a place'})).html_safe
  end
end