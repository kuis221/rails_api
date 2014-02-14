module UsersHelper
  def notifications_for_company_user(user)
    alerts = []
    company = user.company

    # Gets the counts with a single Solr request
    status_counts = {late: 0, due: 0, submitted: 0, rejected: 0}
    events_search = Event.do_search({company_id: company.id, status: ['Active'], user: [user.id], team: user.team_ids}, true)
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

    user.notifications.find_each do |notification|
      alerts.push({
        message: I18n.translate("notifications.#{notification.message}", notification.message_params), level: notification.level,
        url: notification.path + (notification.path.index('?').nil? ?  "?" : '&') + "notifid=#{notification.id}",
        unread: true, icon: 'icon-notification-'+ notification.icon, type: notification.message
      }.merge(notification.extra_params || {} ))
    end

    alerts
  end
end