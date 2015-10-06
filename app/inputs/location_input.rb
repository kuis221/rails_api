class LocationInput < SimpleForm::Inputs::Base
  def input(_wrapper_options)
    data = input_html_options.delete(:data)
    hidden = @builder.hidden_field(attribute_name, input_html_options).to_s
    match = hidden.match(/\s+id="([^"]+)"\s+/)
    hidded_id = match[1]
    (@builder.hidden_field(attribute_name, input_html_options) + ' ' +
      @builder.text_field(nil, name: "#{attribute_name}",
                               'data-hidden' => "##{hidded_id}",
                               data: data,
                               id: "#{hidded_id}_ac",
                               value: input_html_options[:display_value],
                               class:   "places-autocomplete #{input_html_options[:class].join(' ')}",
                               placeholder: 'Search for a place')).html_safe
  end
end
