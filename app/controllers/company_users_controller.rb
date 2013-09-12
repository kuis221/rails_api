class CompanyUsersController < FilteredController
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update, :time_zone_change]
  respond_to :json, only: [:index, :notifications]

  helper_method :assignable_campaigns

  custom_actions collection: [:complete, :time_zone_change]

  def autocomplete
    buckets = autocomplete_buckets({
      users: [CompanyUser],
      teams: [Team],
      roles: [Role],
      campaigns: [Campaign],
      places: [Place]
    })

    render :json => buckets.flatten
  end

  def time_zone_change
    current_user.update_column(:detected_time_zone, params[:time_zone])
  end

  def select_company
    begin
      company = current_user.company_users.find_by_company_id_and_active(params[:company_id], true) or raise ActiveRecord::RecordNotFound
      current_user.current_company = company.company
      current_user.save
      session[:current_company_id] = company.company_id
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "You are not allowed login into this company"
    end
    redirect_to root_path
  end

  def assignable_campaigns
    current_company.campaigns.active.order('campaigns.name asc')
  end

  def update
    resource.user.updating_user = true if resource.id != current_company_user.id
    update! do |success, failure|
      success.js {
        if resource.user.id == current_user.id
          sign_in resource.user, :bypass => true
        end
      }
    end
  end

  def notifications
    alerts = []
    user = current_company_user

    # Due event recaps
    if (count = Event.active.unsent.in_past.with_user_in_team(user).where('events.end_at > ?', 2.days.ago).count) > 0
      alerts.push({message: I18n.translate('notifications.event_recaps_due', count: count), level: 'warning', url: events_path(event_status: ['Due']), unread: true, icon: 'icon-notification-event'})
    end

    # Late event recaps
    if (count = Event.active.unsent.in_past.with_user_in_team(user).where('events.end_at < ?', 2.days.ago).count) > 0
      alerts.push({message: I18n.translate('notifications.event_recaps_late', count: count), level: 'critical', url: events_path(event_status: ['Late']), unread: true, icon: 'icon-notification-event'})
    end

    # Recaps pending approval
    if (count = Event.active.submitted.in_past.with_user_in_team(user).count) > 0
      alerts.push({message: I18n.translate('notifications.recaps_prending_approval', count: count), level: 'critical', url: events_path(event_status: ['Pending']), unread: true, icon: 'icon-notification-event'})
    end

    # Rejected recaps
    if (count = Event.active.rejected.in_past.with_user_in_team(user).count) > 0
      alerts.push({message: I18n.translate('notifications.rejected_recaps', count: count), level: 'critical', url: events_path(event_status: ['Rejected']), unread: true, icon: 'icon-notification-event'})
    end

    # User's teams late tasks
    if (count = Task.active.late.assigned_to(user.find_users_in_my_teams).count) > 0
      alerts.push({message: I18n.translate('notifications.task_late_team', count: count), level: 'critical', url: my_teams_tasks_path(status: ['Active', 'Late']), unread: true, icon: 'icon-notification-task'})
    end

    # User's late tasks
    if (count = user.tasks.active.late.count) > 0
      alerts.push({message: I18n.translate('notifications.task_late_user', count: count), level: 'critical', url: mine_tasks_path(status: ['Active', 'Late']), unread: true, icon: 'icon-notification-task'})
    end


    # Unread comments in user's tasks
    tasks = Task.where(id: Comment.not_from(user.user).for_tasks_assigned_to(user).unread_by(user.user).select('commentable_id')).all
    tasks.each do |task|
      alerts.push({message: I18n.translate('notifications.unread_tasks_comments_user', task: task.title), level: 'info', url: mine_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"), unread: true, icon: 'icon-notification-comment'})
    end

    # Unread comments in user teams' tasks
    tasks = Task.where(id: Comment.not_from(user.user).for_tasks_assigned_to(user.find_users_in_my_teams).unread_by(user.user).select('commentable_id')).all
    tasks.each do |task|
      alerts.push({message: I18n.translate('notifications.unread_tasks_comments_team', task: task.title), level: 'info', url: my_teams_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"), unread: true, icon: 'icon-notification-comment'})
    end

    current_company_user.notifications.each do |notification|
      alerts.push({message: I18n.translate("notifications.#{notification.message}"), level: notification.level, url: notification.path + (notification.path.index('?').nil? ?  "?" : '&') + "notifid=#{notification.id}" , unread: true, icon: 'icon-notification-'+ notification.icon})
    end

    render json: alerts
  end

  protected

    def roles
      @roles ||= current_company.roles
    end

    def as_role
      { as: :admin }
    end

    def role_given?
      current_user.id != resource.user_id
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)
        f.push(label: "Roles", items: facet_search.facet(:role).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :role}) } )
        f.push(label: "Campaigns", items: facet_search.facet(:campaigns).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :campaign}) })
        f.push(label: "Teams", items: facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :team}) })
        f.push(label: "Active State", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
    end

    def delete_member_path(user)
      path = nil
      path = delete_member_team_path(params[:team], member_id: user.id) if params.has_key?(:team) && params[:team]
      path = delete_member_campaign_path(params[:campaign], member_id: user.id) if params.has_key?(:campaign) && params[:campaign]
      path
    end

end
