ActiveAdmin.register Company do
  actions :index, :show, :edit, :update, :new, :create

  filter :name

  form do |f|
    f.inputs 'Details' do
      f.input :name
      f.input :admin_email if f.object.new_record?
    end
    f.inputs 'Settings' do
      f.input :timezone_support,
              hint: 'Turn this ON to display all events with the same timezone as they were scheduled. Ignoring the current user\'s timezone setting.'

      f.input :event_alerts_policy,
              as: :radio,
              hint: 'If "All users" selected, all users with permissions to see the event/task will receive the notification, otherwise, only users in the event\'s team will be notified',
              collection: [
                ['Event Team', Notification::EVENT_ALERT_POLICY_TEAM],
                ['All users', Notification::EVENT_ALERT_POLICY_ALL]
              ]

      f.input :expense_categories,
              hint: 'Enter one category per line'

      f.input :auto_match_events,
              label: 'Auto match events in visits',
              as: :boolean
      f.input :brand_ambassadors_role_ids,
              label: 'Brand Ambassadors Roles',
              as: :check_boxes,
              multiple: true,
              required: false,
              hint: 'Select a role to build the list of "Employees" in the different places inside the Brand Ambassadors section',
              collection: f.object.roles.pluck(:name, :id)

      f.input :ytd_dates_range,
              label: 'YTD Dates Range',
              as: :radio,
              hint: 'Select the YTD Dates Range for filters',
              collection: [
                ['YTD', Company::YTD_DEFAULT],
                ['July 1 - June 30', Company::YTD_JULY1_JUNE30]
              ]

      f.input :kbmg_enabled,
              label: 'Enable KBMG integration',
              as: :radio,
              hint: 'Enable synchronization between visits and KBMG'
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
      row :timezone_support do
        company.timezone_support ? 'Yes' : 'No'
      end
      row :event_alerts_policy do
        case company.event_alerts_policy
        when Notification::EVENT_ALERT_POLICY_TEAM
          'Event Team'
        when Notification::EVENT_ALERT_POLICY_ALL
          'All users'
        end
      end
      row :auto_match_events, 'Auto match events in visits' do
        company.auto_match_events == 1 ? 'Yes' : 'No'
      end
      row 'Brand Ambassadors Roles' do
        company.roles.where(id: company.brand_ambassadors_role_ids).pluck(:name).join(', ')
      end
      row 'YTD Dates Range' do
        case company.ytd_dates_range
        when Company::YTD_DEFAULT
          'YTD'
        when Company::YTD_JULY1_JUNE30
          'July 1 - June 30'
        end
      end
      row 'KBMG Enabled?' do
        company.kbmg_enabled? ? 'Yes' : 'No'
      end
    end
  end

  controller do
    def permitted_params
      params.permit(company: [:name, :admin_email, :timezone_support, :event_alerts_policy,
                              :ytd_dates_range, :expense_categories, :auto_match_events,
                              :kbmg_enabled,
                              brand_ambassadors_role_ids: []])
    end
  end
end
