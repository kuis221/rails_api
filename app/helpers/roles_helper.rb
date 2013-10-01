module RolesHelper
	def permission_checkbox(f, action, subject_class)
    f.fields_for :permissions, resource.permission_for(action, subject_class) do |pf|
      content_tag :label do
        pf.check_box(:enabled, value: true) +
        pf.input(:action, as: :hidden, wrapper: false, label: false) +
        pf.input(:subject_class, as: :hidden, wrapper: false, label: false)
      end
    end
  end
end