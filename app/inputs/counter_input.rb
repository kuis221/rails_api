class CounterInput < SimpleForm::Inputs::Base
  def input(_wrapper_options)
    h.content_tag(:div, class: 'input-append counter-input-grp') do
      @builder.text_field(attribute_name, input_html_options) +
        h.content_tag(:div, class: 'add-on') do
        h.content_tag(:button, h.content_tag(:i, nil, class: 'icon icon-expanded'), class: 'btn increase') +
          h.content_tag(:button, h.content_tag(:i, nil, class: 'icon icon-collapsed'), class: 'btn decrease')
        end
    end
  end

  def h
    @builder.template
  end
end
