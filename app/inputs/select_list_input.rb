class SelectListInput < SimpleForm::Inputs::Base
  def input(_wrapper_options)
    value = object.send(attribute_name)
    template.text_field_tag('q', '', class: 'search-box select-list-seach-box',
                                     placeholder: options[:search_box_placeholder],
                                     data: { list: '#' + select_list_id }) +
    template.content_tag(:div, id:  select_list_id, class: 'resource-list select-list single-line select-list-input') do
      options[:collection].map do |item|
        template.content_tag(:div, class: 'resource-item') do
          template.content_tag(:label, class: 'radio resource-item-link') do
            item[0].html_safe +
            @builder.radio_button(attribute_name, item[1], input_html_options)
          end
        end
      end.join.html_safe
    end
  end

  def select_list_id
    "#{object_name}_#{attribute_name}-list"
      .gsub(/[\[\]]+\z/, '')
      .gsub(/[\[\]]+/, '_')
      .gsub(/_+/, '_')
  end
end
