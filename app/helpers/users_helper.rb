module UsersHelper
  def notifications_for_company_user(user)
    alerts = []
    company = user.company

    if can?(:view_list, Event)
      # Gets the counts with a single Solr request
      status_counts = {late: 0, due: 0, submitted: 0, rejected: 0}
      events_search = Event.do_search({company_id: company.id, status: ['Active'], current_company_user: current_company_user, user: [user.id], team: user.team_ids}, true)
      events_search.facet(:status).rows.each{|r| status_counts[r.value] = r.count }

      # Due event recaps
      if status_counts[:due] > 0
        alerts.push({
          message: I18n.translate('notifications.event_recaps_due', count: status_counts[:due]),
          level: 'grey', url: events_path(user: [user.id], status: ['Active'],
          event_status: ['Due'], start_date: '', end_date: ''),
          unread: true, icon: 'icon-notification-event', type: 'event_recaps_due',
        })
      end

      # Late event recaps
      if status_counts[:late] > 0
        alerts.push({
          message: I18n.translate('notifications.event_recaps_late', count: status_counts[:late]),
          level: 'red', url: events_path(user: [user.id], status: ['Active'],
          event_status: ['Late'], start_date: '', end_date: ''),
          unread: true, icon: 'icon-notification-event', type: 'event_recaps_late'
        })
      end

      # Recaps pending approval
      if status_counts[:submitted] > 0
        alerts.push({
          message: I18n.translate('notifications.recaps_prending_approval', count: status_counts[:submitted]),
          level: 'blue', url: events_path(user: [user.id], status: ['Active'],
          event_status: ['Submitted'], start_date: '', end_date: ''),
          unread: true, icon: 'icon-notification-event', type: 'event_recaps_pending'
        })
      end

      # Rejected recaps
      if status_counts[:rejected] > 0
        alerts.push({
          message: I18n.translate('notifications.rejected_recaps', count: status_counts[:rejected]),
          url: events_path(user: [user.id], status: ['Active'], event_status: ['Rejected'], start_date: '', end_date: ''),
          unread: true, level: 'red',  icon: 'icon-notification-event', type: 'event_recaps_rejected'
        })
      end
    end

    # User's teams late tasks
    if can?(:index_team, Task)
      count = Task.do_search({company_id: company.id, status: ['Active'], task_status: ['Late'], team_members: [user.id], not_assigned_to: [user.id]}).total
      if count > 0
        alerts.push({
          message: I18n.translate('notifications.task_late_team', count: count), level: 'red',
          url: my_teams_tasks_path(status: ['Active'], task_status: ['Late'], team_members: [user.id], not_assigned_to: [user.id], start_date: '', end_date: ''),
          unread: true, icon: 'icon-notification-task', type: 'team_tasks_late'
        })
      end
    end

    # User's late tasks
    if can?(:index_my, Task)
      count = Task.do_search({company_id: company.id, status: ['Active'], task_status: ['Late'], user: [user.id]}).total
      if count > 0
        alerts.push({
          message: I18n.translate('notifications.task_late_user', count: count), level: 'red',
          url: mine_tasks_path(user: [user.id], status: ['Active'], task_status: ['Late'], start_date: '', end_date: ''),
          unread: true, icon: 'icon-notification-task', type: 'user_tasks_late'
        })
      end
    end

    # Unread comments in user's tasks
    if can?(:index_my, Task) && can?(:index_my_comments, Task)
      tasks = Task.select('id, title').where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_assigned_to(user).unread_by(user.user).to_sql})")
      user_tasks = [0]
      tasks.find_each do |task|
        alerts.push({
          message: I18n.translate('notifications.unread_tasks_comments_user', task: task.title), level: 'grey',
          url: mine_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"),
          unread: true, icon: 'icon-notification-comment', type: 'user_task_comments', task_id: task.id
        })
        user_tasks.push task.id
      end
    end

    # Unread comments in user teams' tasks
    if can?(:index_team, Task) && can?(:index_team_comments, Task)
      user_tasks = user_tasks.presence || Task.select('id, title').where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_assigned_to(user).unread_by(user.user).to_sql})").map(&:id)+[0]
      tasks = Task.select('id, title').where("id not in (?)", user_tasks).where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_where_user_in_team(user).unread_by(user.user).to_sql})")
      tasks.find_each do |task|
        alerts.push({
          message: I18n.translate('notifications.unread_tasks_comments_team', task: task.title), level: 'grey',
          url: my_teams_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"),
          unread: true, icon: 'icon-notification-comment', type: 'team_task_comments', task_id: task.id
        })
      end
    end

    grouped_notifications = Notification.grouped_notifications_counts(current_company_user.notifications)

    # New events notifications
    if grouped_notifications['new_event'].present? && grouped_notifications['new_event'].to_i > 0 && can?(:view_list, Event)
      alerts.push({
        message: I18n.translate("notifications.new_events", count: grouped_notifications['new_event'].to_i), level: 'grey',
        url: events_path(new_at: Time.now.to_i, start_date: '', end_date: ''),
        unread: true, icon: 'icon-notification-event', type: 'new_event'
      })
    end

    # New team events notifications
    if grouped_notifications['new_team_event'].present? && grouped_notifications['new_team_event'].to_i > 0 && can?(:view_list, Event)
      team_ids = user.notifications.new_team_events.map{|n| n.message_params[:team_id]}.sort.uniq
      team_names = user.notifications.new_team_events.map{|n| n.message_params[:team_name]}.uniq.sort.join(', ')
      events_count = grouped_notifications['new_team_event'].to_i
      events_sentence = events_count > 1 ? "#{events_count} new events" : 'a new event'
      alerts.push({
        message: I18n.translate("notifications.new_team_events", count: team_ids.count, teams_names: team_names, events_sentence: events_sentence), level: 'grey',
        url: events_path(notification: 'new_team_event', team: team_ids, new_at: Time.now.to_i, start_date: '', end_date: ''),
        unread: true, icon: 'icon-notification-event', type: 'new_team_event'
      })
    end

    # New campaigns notifications
    if grouped_notifications['new_campaign'].present? && grouped_notifications['new_campaign'].to_i > 0 && can?(:read, Campaign)
      alerts.push({
        message: I18n.translate("notifications.new_campaigns", count: grouped_notifications['new_campaign'].to_i), level: 'grey',
        url: campaigns_path(new_at: Time.now.to_i),
        unread: true, icon: 'icon-notification-campaign', type: 'new_campaign'
      })
    end

    # New user tasks notifications
    if grouped_notifications['new_task'].present? && grouped_notifications['new_task'].to_i > 0 && can?(:index_my, Task)
      alerts.push({
        message: I18n.translate("notifications.new_tasks", count: grouped_notifications['new_task'].to_i), level: 'grey',
        url: mine_tasks_path(new_at: Time.now.to_i),
        unread: true, icon: 'icon-notification-task', type: 'new_task'
      })
    end

    # New user team tasks notifications
    # if grouped_notifications['new_team_task'].present? && grouped_notifications['new_team_task'].to_i > 0
    #   alerts.push({
    #     message: I18n.translate("notifications.my_teams_tasks_path", count: grouped_notifications['new_team_task'].to_i), level: 'grey',
    #     url: mine_tasks_path(new_at: Time.now.to_i),
    #     unread: true, icon: 'icon-notification-task', type: 'new_team_task'
    #   })
    # end

    user.notifications.except_grouped_notifications.find_each do |notification|
      alerts.push({
        message: I18n.translate("notifications.#{notification.message}", notification.message_params), level: notification.level,
        url: notification.path,
        unread: true, icon: 'icon-notification-'+ notification.icon, type: notification.message
      }.merge(notification.params || {} ))
    end

    alerts
  end
end