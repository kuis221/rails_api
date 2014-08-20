module UsersHelper
  def notifications_for_company_user(user)
    Rails.cache.fetch("user_notifications_#{user.id}", expires_in: 15.minutes) do
      alerts = []
      company = user.company

      if can?(:view_list, Event)
        # Gets the counts with a single Solr request
        status_counts = {late: 0, due: 0, submitted: 0, rejected: 0}
        event_search_params = {
          company_id: company.id,
          status: ['Active'],
          current_company_user: current_company_user }

        user_params = nil
        # If the notification policy is set to only event team members
        unless user.company.event_alerts_policy == Notification::EVENT_ALERT_POLICY_ALL
          event_search_params.merge!(user: [user.id], team: user.team_ids)
          user_params = [user.id]
        end
        events_search = Event.do_search(event_search_params, true)
        events_search.facet(:status).rows.each{|r| status_counts[r.value] = r.count }

        # Due event recaps
        if status_counts[:due] > 0 && user.allow_notification?('event_recap_due_app')
          alerts.push({
            message: I18n.translate('notifications.event_recaps_due', count: status_counts[:due]),
            level: 'grey', url: events_path(user: user_params, status: ['Active'],
            event_status: ['Due'], start_date: '', end_date: ''),
            unread: true, icon: 'icon-events', type: 'event_recaps_due',
          })
        end
        # Late event recaps
        if status_counts[:late] > 0 && user.allow_notification?('event_recap_late_app')
          alerts.push({
            message: I18n.translate('notifications.event_recaps_late', count: status_counts[:late]),
            level: 'red', url: events_path(user: user_params, status: ['Active'],
            event_status: ['Late'], start_date: '', end_date: ''),
            unread: true, icon: 'icon-events', type: 'event_recaps_late'
          })
        end

        # Recaps pending approval
        if status_counts[:submitted] > 0 && user.allow_notification?('event_recap_pending_approval_app')
          alerts.push({
            message: I18n.translate('notifications.recaps_prending_approval', count: status_counts[:submitted]),
            level: 'blue', url: events_path(user: user_params, status: ['Active'],
            event_status: ['Submitted'], start_date: '', end_date: ''),
            unread: true, icon: 'icon-events', type: 'event_recaps_pending'
          })
        end

        # Rejected recaps
        if status_counts[:rejected] > 0 && user.allow_notification?('event_recap_rejected_app')
          alerts.push({
            message: I18n.translate('notifications.rejected_recaps', count: status_counts[:rejected]),
            url: events_path(user: user_params, status: ['Active'], event_status: ['Rejected'], start_date: '', end_date: ''),
            unread: true, level: 'red',  icon: 'icon-events', type: 'event_recaps_rejected'
          })
        end
      end

      # User's teams late tasks
      if can?(:index_team, Task) && user.allow_notification?('late_team_task_app')
        team_params = nil
        unless user.company.event_alerts_policy == Notification::EVENT_ALERT_POLICY_ALL
          team_params = [user.id]
        end
        task_search_params = {company_id: company.id, status: ['Active'], task_status: ['Late'], not_assigned_to: [user.id], team_members: team_params}
        count = Task.do_search(task_search_params).total
        if count > 0
          alerts.push({
            message: I18n.translate('notifications.task_late_team', count: count), level: 'red',
            url: my_teams_tasks_path(status: ['Active'], task_status: ['Late'], team_members: team_params, not_assigned_to: [user.id], start_date: '', end_date: ''),
            unread: true, icon: 'icon-tasks', type: 'team_tasks_late'
          })
        end
      end

      # User's late tasks
      if can?(:index_my, Task) && user.allow_notification?('late_task_app')
        count = Task.do_search({company_id: company.id, status: ['Active'], task_status: ['Late'], user: [user.id]}).total
        if count > 0
          alerts.push({
            message: I18n.translate('notifications.task_late_user', count: count), level: 'red',
            url: mine_tasks_path(user: [user.id], status: ['Active'], task_status: ['Late'], start_date: '', end_date: ''),
            unread: true, icon: 'icon-tasks', type: 'user_tasks_late'
          })
        end
      end

      # Unread comments in user's tasks
      if can?(:index_my, Task) && can?(:index_my_comments, Task) && user.allow_notification?('new_comment_app')
        tasks = Task.select('id, title').where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_assigned_to(user).unread_by(user.user).to_sql})")
        user_tasks = [0]
        tasks.find_each do |task|
          alerts.push({
            message: I18n.translate('notifications.unread_tasks_comments_user', task: task.title), level: 'grey',
            url: mine_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"),
            unread: true, icon: 'icon-comments', type: 'user_task_comments', task_id: task.id
          })
          user_tasks.push task.id
        end
      end

      # Unread comments in user teams' tasks
      if can?(:index_team, Task) && can?(:index_team_comments, Task) && user.allow_notification?('new_team_comment_app')
        user_tasks = user_tasks.presence || Task.select('id, title').where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_assigned_to(user).unread_by(user.user).to_sql})").map(&:id)+[0]
        tasks = Task.select('id, title').where("id not in (?)", user_tasks).where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_where_user_in_team(user).unread_by(user.user).to_sql})")
        tasks.find_each do |task|
          alerts.push({
            message: I18n.translate('notifications.unread_tasks_comments_team', task: task.title), level: 'grey',
            url: my_teams_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"),
            unread: true, icon: 'icon-comments', type: 'team_task_comments', task_id: task.id
          })
        end
      end

      grouped_notifications = Notification.grouped_notifications_counts(current_company_user.notifications)

      timestamp = Time.now.to_datetime.strftime('%Q').to_i
      # New events notifications
      if grouped_notifications['new_event'].present? && grouped_notifications['new_event'].to_i > 0 && can?(:view_list, Event) && user.allow_notification?('new_event_team_app')
        alerts.push({
          message: I18n.translate("notifications.new_events", count: grouped_notifications['new_event'].to_i), level: 'grey',
          url: events_path(new_at: timestamp, start_date: '', end_date: ''),
          unread: true, icon: 'icon-events', type: 'new_event'
        })
      end

      # New team events notifications
      if grouped_notifications['new_team_event'].present? && grouped_notifications['new_team_event'].to_i > 0 && can?(:view_list, Event) && user.allow_notification?('new_event_team_app')
        team_ids = user.notifications.new_team_events.map{|n| n.message_params[:team_id]}.sort.uniq
        team_names = user.notifications.new_team_events.map{|n| n.message_params[:team_name]}.uniq.sort.join(', ')
        events_count = grouped_notifications['new_team_event'].to_i
        events_sentence = events_count > 1 ? "#{events_count} new events" : 'a new event'
        alerts.push({
          message: I18n.translate("notifications.new_team_events", count: team_ids.count, teams_names: team_names, events_sentence: events_sentence), level: 'grey',
          url: events_path(notification: 'new_team_event', team: team_ids, new_at: timestamp, start_date: '', end_date: ''),
          unread: true, icon: 'icon-events', type: 'new_team_event'
        })
      end

      # New campaigns notifications
      if grouped_notifications['new_campaign'].present? && grouped_notifications['new_campaign'].to_i > 0 && can?(:read, Campaign) && user.allow_notification?('new_campaign_app')
        alerts.push({
          message: I18n.translate("notifications.new_campaigns", count: grouped_notifications['new_campaign'].to_i), level: 'grey',
          url: campaigns_path(new_at: timestamp),
          unread: true, icon: 'icon-campaign', type: 'new_campaign'
        })
      end

      # New user tasks notifications
      if grouped_notifications['new_task'].present? && grouped_notifications['new_task'].to_i > 0 && can?(:index_my, Task) && user.allow_notification?('new_task_assignment_app')
        alerts.push({
          message: I18n.translate("notifications.new_tasks", count: grouped_notifications['new_task'].to_i), level: 'grey',
          url: mine_tasks_path(new_at: timestamp),
          unread: true, icon: 'icon-tasks', type: 'new_task'
        })
      end

      # New user team tasks notifications
      # if grouped_notifications['new_team_task'].present? && grouped_notifications['new_team_task'].to_i > 0 && user.allow_notification?('new_unassigned_team_task_app')
      #   alerts.push({
      #     message: I18n.translate("notifications.my_teams_tasks_path", count: grouped_notifications['new_team_task'].to_i), level: 'grey',
      #     url: mine_tasks_path(new_at: timestamp),
      #     unread: true, icon: 'icon-tasks', type: 'new_team_task'
      #   })
      # end

      user.notifications.except_grouped_notifications.find_each do |notification|
        alerts.push({
          message: I18n.translate("notifications.#{notification.message}", notification.message_params), level: notification.level,
          url: notification.path,
          unread: true, icon: 'icon-'+ notification.icon, type: notification.message
        }.merge(notification.params || {} ))
      end

      alerts
    end
  end

  def notification_setting_checkbox(type, subject)
    field_id = "#{type}_#{subject}"
    content_tag(:label, check_box_tag("company_user[notifications_settings][]", field_id, resource.notifications_settings.include?(field_id), id: "notification_settings_#{field_id}"))
  end
end