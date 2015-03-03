module RolesHelper
  def permission_checkbox(f, action, subject_class, subject: nil, allow_all: false)
    field_id = "permission_#{action}_#{subject_class.to_s.downcase}" + (subject.nil? ? '' : '_' + (subject.respond_to?(:id) ? subject.id : subject.to_s.downcase))
    f.fields_for :permissions, resource.permission_for(action, subject_class, subject: subject) do |pf|
      current_icon = 'icon-role-' + pf.object.mode
      content_tag(:div, class: 'role-permission-item') do
        pf.hidden_field(:mode, class: 'role-permission-value') +
        content_tag(:i, nil, class: 'toggle-permission-btn icon-role ' + current_icon, data: { 'allow-all' => allow_all }) +
        pf.hidden_field(:action) +
        pf.hidden_field(:subject_class) +
        (subject.nil? ? '' : pf.input(:subject_id, as: :hidden, wrapper: false, label: false))
      end
    end
  end
end
