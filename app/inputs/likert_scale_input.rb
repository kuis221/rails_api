class LikertScaleInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    values = object.send(attribute_name)
    group = "#{object_name}_#{attribute_name}".gsub(/[\[\]]+\z/, '').gsub(/[\[\]]+/, '_').gsub(/_+/, '_')
    '<table class="table likert-scale-table likert-scale-' + options[:field_id].to_s + '">' \
       '<thead><tr><th></th>' + options[:collection].map { |o| "<th><label class=\"likert-option\">#{o.name}</label></th>" }.join + '</tr></thead>' \
       '<tbody>' +
    options[:statements].map do |statement|
      '<tr class="likert-fields"><td><label class="likert-statement">' + statement.name + '</label></td>' + options[:collection].map do |option|
        field_name = "#{object_name}[#{attribute_name}][#{statement.id}]"
        field_id = "#{group}_#{statement.id}"
        if options[:multiple] == false # Single Answer
          value = values.try(:[], statement.id.to_s).to_i
          checked = value == option.id ? ' checked="checked"' : ''
          '<td><label class="radio"><div class="radio"><input type="radio" name="' + field_name + '" id="' + field_id + '_' + option.id.to_s + '" value="' + option.id.to_s + '"' + checked + ' class="likert-field" data-likert-error-id="' + options[:field_id].to_s + '"></div></label></td>'
        else # Multiple Answer
          value = eval(values[statement.id.to_s]) if values[statement.id.to_s].present?
          checked = value.present? && value.is_a?(Array) && value.include?(option.id.to_s) ? ' checked="checked"' : ''
          field_name = "#{object_name}[#{attribute_name}][#{statement.id}][]"
          '<td><label class="checkbox multiple"><div class="checkbox"><input type="checkbox" name="' + field_name + '" id="' + field_id + '_' + option.id.to_s + '" value="' + option.id.to_s + '"' + checked + ' class="likert-field" data-likert-error-id="' + options[:field_id].to_s + '"></div></label></td>'
        end
      end.join + '</tr>'
    end.join + '</tbody></table>'.html_safe
  end
end
