class LikertScaleInput < SimpleForm::Inputs::Base
  def input
    values = object.send(attribute_name)
    group = "#{object_name}_#{attribute_name}".gsub(/[\[\]]+\z/,'').gsub(/[\[\]]+/,'_').gsub(/_+/,'_')
    '<table class="table likert-scale-table">' +
       '<thead><tr><th></th>' + options[:collection].map{|o| "<th><label>#{o.name}</label></th>" }.join + '</tr></thead>' +
       '<tbody>' +
    options[:statements].map do |statement|
      value = values.try(:[], statement.id.to_s).to_i
      '<tr><td><label>'+statement.name+'</label></td>' + options[:collection].map do |option|
        field_name = "#{object_name}[#{attribute_name}][#{statement.id}]"
        field_id = "#{group}_#{statement.id}"
        checked = if value == option.id then ' checked="checked"' else '' end
        '<td><label class="radio"><div class="radio"><input type="radio" name="'+field_name+'" id="'+field_id+'_'+option.id.to_s+'" value="'+option.id.to_s+'"'+checked+'></div></label></td>'
      end.join + '</tr>'
    end.join + '</tbody></table>'.html_safe
  end
end