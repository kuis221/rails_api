ActiveAdmin.register Company do
  actions :index, :show, :edit, :update, :new, :create

  filter :name

  form do |f|
    f.inputs "Details" do
      f.input :name
      f.input :admin_email if f.object.new_record?
    end
    f.inputs "Date/Time Settings" do
      f.input :timezone_support,
        hint: 'Turn this ON to display all events with the same timezone as they were scheduled. Ignoring the current user\'s timezone setting.'
    end
    f.inputs name: "Notifications Settings", for: :settings do |settings_form|
      settings_form.input :event_alerts_policy,
        as: :radio,
        hint: 'If "All users" selected, all users with permissions to see the event/task will receive the notification, otherwise, only users in the event\'s team will be notified',
        collection: [
          ['Event Team', Notification::EVENT_ALERT_POLICY_TEAM.to_i, {checked: f.object.settings['event_alerts_policy'].try(:to_i) == Notification::EVENT_ALERT_POLICY_TEAM.to_i}],
          ['All users', Notification::EVENT_ALERT_POLICY_ALL.to_i, {checked: f.object.settings['event_alerts_policy'].try(:to_i) == Notification::EVENT_ALERT_POLICY_ALL.to_i}]
        ]
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit(:company => [:name, :admin_email, :timezone_support, settings: [:event_alerts_policy]])
    end
  end
end