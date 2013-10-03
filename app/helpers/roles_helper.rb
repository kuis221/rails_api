module RolesHelper
	def permission_checkbox(f, action, subject_class, subject=nil)
    f.fields_for :permissions, resource.permission_for(action, subject_class, subject) do |pf|
      content_tag :div do
        pf.check_box(:enabled, value: true) +
        pf.input(:action, as: :hidden, wrapper: false, label: false) +
        pf.input(:subject_class, as: :hidden, wrapper: false, label: false) +
        (subject.nil? ? '' : pf.input(:subject_id, as: :hidden, wrapper: false, label: false))
      end
    end
  end
end