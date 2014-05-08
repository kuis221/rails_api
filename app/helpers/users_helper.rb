module UsersHelper
  def notifications_for_company_user(user)
    alerts = []
    company = user.company

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

    # User's teams late tasks
    count = Task.do_search({company_id: company.id, status: ['Active'], task_status: ['Late'], team_members: [user.id], not_assigned_to: [user.id]}).total
    if count > 0
      alerts.push({
        message: I18n.translate('notifications.task_late_team', count: count), level: 'red',
        url: my_teams_tasks_path(status: ['Active'], task_status: ['Late'], team_members: [user.id], not_assigned_to: [user.id], start_date: '', end_date: ''),
        unread: true, icon: 'icon-notification-task', type: 'team_tasks_late'
      })
    end

    # User's late tasks
    count = Task.do_search({company_id: company.id, status: ['Active'], task_status: ['Late'], user: [user.id]}).total
    if count > 0
      alerts.push({
        message: I18n.translate('notifications.task_late_user', count: count), level: 'red',
        url: mine_tasks_path(user: [user.id], status: ['Active'], task_status: ['Late'], start_date: '', end_date: ''),
        unread: true, icon: 'icon-notification-task', type: 'user_tasks_late'
      })
    end

    # Unread comments in user's tasks
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

    # Unread comments in user teams' tasks
    tasks = Task.select('id, title').where("id not in (?)", user_tasks).where("id in (#{Comment.select('commentable_id').not_from(user.user).for_tasks_where_user_in_team(user).unread_by(user.user).to_sql})")
    tasks.find_each do |task|
      alerts.push({
        message: I18n.translate('notifications.unread_tasks_comments_team', task: task.title), level: 'grey',
        url: my_teams_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"),
        unread: true, icon: 'icon-notification-comment', type: 'team_task_comments', task_id: task.id
      })
    end

    grouped_notifications = Notification.grouped_notifications_counts(current_company_user.notifications)

    # New events notifications
    if grouped_notifications['new_event'].present? && grouped_notifications['new_event'].to_i > 0
      alerts.push({
        message: I18n.translate("notifications.new_events", count: grouped_notifications['new_event'].to_i), level: 'grey',
        url: events_path(new_at: Time.now.to_i, start_date: '', end_date: ''),
        unread: true, icon: 'icon-notification-event', type: 'new_event'
      })
    end

    # New campaigns notifications
    if grouped_notifications['new_campaign'].present? && grouped_notifications['new_campaign'].to_i > 0
      notification_params = current_company_user.notifications.where(message: 'new_campaign').pluck(:extra_params)
      ids = notification_params.map{|param| param[:campaign_id] }.compact
      alerts.push({
        message: I18n.translate("notifications.new_campaigns", count: grouped_notifications['new_campaign'].to_i), level: 'grey',
        url: events_path(campaign: ids, notification: 'new_campaign', new_at: Time.now.to_i, start_date: '', end_date: ''),
        unread: true, icon: 'icon-notification-campaign', type: 'new_campaign'
      })
    end

    # New user tasks notifications
    if grouped_notifications['new_task'].present? && grouped_notifications['new_task'].to_i > 0
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
        url: notification.path + (notification.path.index('?').nil? ?  "?" : '&') + "notifid=#{notification.id}",
        unread: true, icon: 'icon-notification-'+ notification.icon, type: notification.message
      }.merge(notification.extra_params || {} ))
    end

    alerts
  end
end