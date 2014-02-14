class DatePickerInput < SimpleForm::Inputs::Base
  def input
    if options[:inline]
      @builder.template.content_tag(:div, '', data:{date: object.send(attribute_name)}, id: "calendar_#{attribute_name}", class: :datepicker)+
      "#{@builder.input_field(attribute_name, as: :hidden)}".html_safe
    else
      input_html_options[:class] += ['datepicker']
      value = object.send(attribute_name)
      value = value.try(:to_s, :slashes) if value.is_a?(Date) || value.is_a?(DateTime) || value.is_a?(Time)
      "#{@builder.text_field(attribute_name, input_html_options.merge({value: value}))}".html_safe
    end
  end
end