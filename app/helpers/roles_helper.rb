module RolesHelper
	def permission_checkbox(f, action, subject_class, subject=nil)
    field_id = "permission_#{action}_#{subject_class.to_s.downcase}" + (subject.nil? ? '' : '_'+(subject.respond_to?(:id) ? subject.id : subject.to_s.downcase) )
    f.fields_for :permissions, resource.permission_for(action, subject_class, subject) do |pf|
      pf.input(:enabled, as: :hidden, wrapper: false, label: false, input_html: { value: '0' }) +
      content_tag(:label, pf.check_box(:enabled, {id: field_id},1, nil)) +
      pf.input(:action, as: :hidden, wrapper: false, label: false) +
      pf.input(:subject_class, as: :hidden, wrapper: false, label: false) +
      (subject.nil? ? '' : pf.input(:subject_id, as: :hidden, wrapper: false, label: false))
    end
  end
end