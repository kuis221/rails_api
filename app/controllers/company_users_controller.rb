class CompanyUsersController < FilteredController
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update, :time_zone_change]
  respond_to :json, only: [:index, :notifications]

  helper_method :brands_campaigns_list

  custom_actions collection: [:complete, :time_zone_change]

  before_filter :validate_parent, only: [:enable_campaigns, :disable_campaigns, :remove_campaign, :select_campaigns, :add_campaign]

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

  def enable_campaigns
    if params[:parent_type] && params[:parent_id]
      parent_membership = resource.memberships.find_or_create_by_memberable_type_and_memberable_id(params[:parent_type], params[:parent_id])
      @parent = parent_membership.memberable
      @campaigns = @parent.campaigns
      # Delete all campaign associations assigned to this user directly under this brand/portfolio
      resource.memberships.where(parent_id: parent_membership.memberable.id, parent_type: parent_membership.memberable.class.name).destroy_all
    end
  end

  def disable_campaigns
    if params[:parent_type] && params[:parent_id]
      membership = resource.memberships.find_by_memberable_type_and_memberable_id(params[:parent_type], params[:parent_id])
      resource.memberships.where(parent_id: membership.memberable.id, parent_type: membership.memberable.class.name).destroy_all
      # Assign all the campaings directly to the user
      membership.memberable.campaigns.each do |campaign|
        resource.memberships.create({memberable: campaign, parent: membership.memberable}, without_protection: true)
      end
      membership.destroy
    end
    render text: 'OK'
  end

  def remove_campaign
    if params[:parent_type] && params[:parent_id] && params[:campaign_id]
      membership = resource.memberships.where(memberable_type: params[:parent_type], memberable_id: params[:parent_id]).first
      # If the parent is directly assigned to the user, then remove the parent and assign all the
      # current campaigns to the user
      unless membership.nil?
        membership.memberable.campaigns.scoped_by_company_id(current_company.id).each do |campaign|
          unless campaign.id == params[:campaign_id].to_i
            resource.memberships.create({memberable: campaign, parent: membership.memberable}, without_protection: true)
          end
        end
        membership.destroy
      else
        membership = resource.memberships.where(parent_type: params[:parent_type], parent_id: params[:parent_id], memberable_type: 'Campaign', memberable_id: params[:campaign_id]).destroy_all
      end
    end
  end

  def select_campaigns
    @campaigns = []
    if params[:parent_type] && params[:parent_id]
      membership = resource.memberships.where(memberable_type: params[:parent_type], memberable_id: params[:parent_id]).first
      if membership.nil?
        parent = params['parent_type'].constantize.find(params['parent_id'])
        @campaigns = parent.campaigns.scoped_by_company_id(current_company.id).where(['campaigns.id not in (?)', resource.campaigns.children_of(parent).map(&:id)+[0]])
      end
    end
  end

  def add_campaign
    if params[:parent_type] && params[:parent_id] && params[:campaign_id]
      @parent = params['parent_type'].constantize.find(params['parent_id'])
      campaign = current_company.campaigns.find(params[:campaign_id])
      resource.memberships.create({memberable: campaign, parent: @parent}, without_protection: true)
      @campaigns = resource.campaigns.children_of(@parent)
    end
  end

  def notifications
    alerts = []
    user = current_company_user

    # Due event recaps
    count = Event.do_search({company_id: current_company.id, status: ['Active'], event_status: ['Due'], user: [user.id], team: user.team_ids}).total
    if count > 0
      alerts.push({message: I18n.translate('notifications.event_recaps_due', count: count), level: 'grey', url: events_path(user: [user.id], status: ['Active'], event_status: ['Due']), unread: true, icon: 'icon-notification-event'})
    end

    # Late event recaps
    count = Event.do_search({company_id: current_company.id, status: ['Active'], event_status: ['Late'], user: [user.id], team: user.team_ids}).total
    if count > 0
      alerts.push({message: I18n.translate('notifications.event_recaps_late', count: count), level: 'red', url: events_path(user: [user.id], status: ['Active'], event_status: ['Late']), unread: true, icon: 'icon-notification-event'})
    end

    # Recaps pending approval
    count = Event.do_search({company_id: current_company.id, status: ['Active'], event_status: ['Submitted'], user: [user.id], team: user.team_ids}).total
    if count > 0
      alerts.push({message: I18n.translate('notifications.recaps_prending_approval', count: count), level: 'blue', url: events_path(user: [user.id], status: ['Active'], event_status: ['Submitted']), unread: true, icon: 'icon-notification-event'})
    end

    # Rejected recaps
    count = Event.do_search({company_id: current_company.id, status: ['Active'], event_status: ['Rejected'], user: [user.id], team: user.team_ids}).total
    if count > 0
      alerts.push({message: I18n.translate('notifications.rejected_recaps', count: count), level: 'red', url: events_path(user: [user.id], status: ['Active'], event_status: ['Rejected']), unread: true, icon: 'icon-notification-event'})
    end

    # User's teams late tasks
    count = Task.do_search({company_id: current_company.id, status: ['Active'], task_status: ['Late'], team_members: [user.id], not_assigned_to: [user.id]}).total
    if count > 0
      alerts.push({message: I18n.translate('notifications.task_late_team', count: count), level: 'red', url: my_teams_tasks_path(status: ['Active'], task_status: ['Late'], team_members: [user.id], not_assigned_to: [user.id]), unread: true, icon: 'icon-notification-task'})
    end

    # User's late tasks
    count = Task.do_search({company_id: current_company.id, status: ['Active'], task_status: ['Late'], user: [user.id]}).total
    if count > 0
      alerts.push({message: I18n.translate('notifications.task_late_user', count: count), level: 'red', url: mine_tasks_path(user: [user.id], status: ['Active'], task_status: ['Late']), unread: true, icon: 'icon-notification-task'})
    end

    # Unread comments in user's tasks
    tasks = Task.where(id: Comment.not_from(user.user).for_tasks_assigned_to(user).unread_by(user.user).select('commentable_id')).all
    tasks.each do |task|
      alerts.push({message: I18n.translate('notifications.unread_tasks_comments_user', task: task.title), level: 'grey', url: mine_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"), unread: true, icon: 'icon-notification-comment'})
    end

    # Unread comments in user teams' tasks
    tasks = Task.where(id: Comment.not_from(user.user).for_tasks_where_user_in_team(user).unread_by(user.user).select('commentable_id')).all
    tasks.each do |task|
      alerts.push({message: I18n.translate('notifications.unread_tasks_comments_team', task: task.title), level: 'grey', url: my_teams_tasks_path(q: "task,#{task.id}", anchor: "comments-#{task.id}"), unread: true, icon: 'icon-notification-comment'})
    end

    user.notifications.each do |notification|
      alerts.push({message: I18n.translate("notifications.#{notification.message}", notification.message_params), level: notification.level, url: notification.path + (notification.path.index('?').nil? ?  "?" : '&') + "notifid=#{notification.id}" , unread: true, icon: 'icon-notification-'+ notification.icon})
    end

    render json: alerts
  end

  protected
    def permitted_params
      allowed = {company_user: [{user_attributes: [:id, :first_name, :last_name, :email, :phone_number, :password, :password_confirmation, :country, :state, :city, :street_address, :unit_number, :zip_code, :time_zone]}] }
      if params[:id].present? && can?(:super_update, CompanyUser.find(params[:id]))
        allowed[:company_user] += [:role_id, {team_ids: []}]
      end
      params.permit(allowed)[:company_user]
    end

    def roles
      @roles ||= current_company.roles
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id, :current_company_user].include?(k.to_sym)})
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


    def brands_campaigns_list
      list = {}
      current_company.brand_portfolios.each do |portfolio|
        enabled = resource.brand_portfolios.include?(portfolio)
        list[portfolio] = {enabled: enabled, campaigns: (enabled ? portfolio.campaigns.scoped_by_company_id(current_company.id) : resource.campaigns.scoped_by_company_id(current_company.id).children_of(portfolio) ) }
      end
      Brand.for_company_campaigns(current_company).each do |brand|
        enabled = resource.brands.include?(brand)
        list[brand] = {enabled: enabled, campaigns: (enabled ? brand.campaigns.scoped_by_company_id(current_company.id) : resource.campaigns.scoped_by_company_id(current_company.id).children_of(brand) ) }
      end
      list
    end


    def validate_parent
      raise CanCan::AccessDenied unless ['BrandPortfolio', 'Brand'].include?(params[:parent_type])
    end

end
