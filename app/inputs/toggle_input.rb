class ToggleInput < SimpleForm::Inputs::Base
  def input
    status = object.send(attribute_name)
    @builder.template.content_tag(:div, class: 'btn-group toggle-input') do
      @builder.template.link_to('On', '#', class: 'btn btn-small set-on-btn' + (status ? ' btn-success active' : ''), 'data-value' => 'true') +      @builder.template.link_to('Off', '#', class: 'btn btn-small set-off-btn' + (status ? '' : ' btn-danger active'), 'data-value' => '') +
      @builder.input_field(attribute_name, value: (status ? 'true' : ''), as: :hidden, class: 'toggle-input-hidden')
    end
  end
end
