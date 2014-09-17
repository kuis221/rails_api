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
    f.inputs name: "Notifications Settings" do
      f.input :event_alerts_policy,
        as: :radio,
        hint: 'If "All users" selected, all users with permissions to see the event/task will receive the notification, otherwise, only users in the event\'s team will be notified',
        collection: [
          ['Event Team', Notification::EVENT_ALERT_POLICY_TEAM],
          ['All users', Notification::EVENT_ALERT_POLICY_ALL]
        ]
    end
    f.inputs name: "Brand Ambassadors" do
      f.input :brand_ambassadors_role_ids,
        label: 'Brand Ambassadors Roles',
        as: :check_boxes,
        multiple: true,
        required: false,
        hint: 'Select a role to build the list of "Employees" in the different places inside the Brand Ambassadors section',
        collection: f.object.roles.pluck(:name, :id)
    end
    f.actions
  end

  index do
    column :id
    column :name
    column :timezone_support
    column :created_at
    column 'BA Roles' do |company|
      company.roles.where(id: company.brand_ambassadors_role_ids).pluck(:name).join(', ')
    end
    actions
  end

  show do |company|
    attributes_table do
      row :id
      row :name
      row :timezone_support
      row :event_alerts_policy do
        case company.event_alerts_policy
        when Notification::EVENT_ALERT_POLICY_TEAM
          'Event Team'
        when Notification::EVENT_ALERT_POLICY_ALL
          'All users'
        end
      end
      row 'Brand Ambassadors Roles' do
        company.roles.where(id: company.brand_ambassadors_role_ids).pluck(:name).join(', ')
      end
    end
  end

  controller do
    def permitted_params
      params.permit(:company => [:name, :admin_email, :timezone_support, :event_alerts_policy, brand_ambassadors_role_ids: []])
    end
  end
end