class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)


    alias_action :activate, :to => :deactivate
    alias_action :new_member, :to => :add_members
    alias_action :new_member, :to => :add_members
    alias_action :add_kpi, :to => :activate_kpis
    alias_action :remove_kpi, :to => :activate_kpis
    alias_action :add_activity_type, :to => :activate_kpis
    alias_action :remove_activity_type, :to => :activate_kpis

    # All users

    if user.id && !user.is_a?(AdminUser)
      can :find_similar_kpi, Campaign do
        can?(:update, Campaign) || can?(:create, Campaign)
      end

      can [:create, :update], Goal do |goal|
        if goal.parent.present?
          can?(:show, goal.parent)
        else
          can?(:edit, goal.goalable)
        end
      end

      can :time_zone_change, CompanyUser
      can :time_zone_update, CompanyUser
      can [:notifications, :select_company], CompanyUser

      # All users can update their own information
      can :update, CompanyUser, id: user.current_company_user.id
      can :update, Campaign, id: user.current_company_user.id

      can :super_update, CompanyUser do |cu|
        user.current_company_user.role.is_admin? || user.current_company_user.role.has_permission?(:update, CompanyUser)
      end

      can [:enable_campaigns, :disable_campaigns, :remove_campaign, :select_campaigns, :add_campaign], CompanyUser do |cu|
        can?(:edit, cu)
      end
    end

    # AdminUsers (logged in on Active Admin)
    if user.is_a?(AdminUser)
      # ActiveAdmin users
      can :manage, :all

    # Super Admin Users
    elsif user.is_super_admin?
      can :manage, :dashboard

      # Super Admin Users can manage any object on the same company
      can do |action, subject_class, subject|
        Rails.logger.debug "Checking #{action} on #{subject_class.to_s} :: #{subject}"
        subject.nil? || ( subject.respond_to?(:company_id) && ((subject.company_id.nil? && [:create, :new].include?(action)) || subject.company_id == user.current_company.id) )
      end

      cannot do |action, subject_class, subject|
        [Company].include?(subject_class)
      end

      # Other permissions
      can [:index, :create], Brand

      can [:new, :create], Kpi do |kpi|
        can?(:edit, Campaign)
      end

      # Special permission to allow editing global kpis (for goals setting)
      can [:edit, :update], Kpi do |kpi|
        kpi.company_id.nil? && can?(:edit, Campaign)
      end

      can :edit_data, Event

    # A logged in user
    elsif user.id
      can do |action, subject_class, subject|
        Rails.logger.debug "Checking #{action} on #{subject_class.to_s} :: #{subject}"
        user.role.cached_permissions.select{|p| aliases_for_action(action).map(&:to_s).include?(p.action.to_s)}.any? do |permission|
          permission.subject_class == subject_class.to_s &&
          (   subject.nil? ||
            ( subject.respond_to?(:company_id) && ((subject.company_id.nil? && [:create, :new].include?(action)) || subject.company_id == user.current_company.id) ) ||
            ( permission.subject_id.nil? || (subject.respond_to?(:id) ? permission.subject_id == subject.id : permission.subject_id == subject.to_s) )
          )
        end
      end

      can :search, Place

      can :index, Event if can?(:view_list, Event) || can?(:view_map, Event)

      can :index, Brand

      can :index, Marque

      can :form, Activity if can?(:create, Activity)

      can :places, Campaign do |campaign|
        user.current_company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can :report, Campaign do |campaign|
        can?(:show_analysis, campaign) && user.current_company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can [:add_place, :remove_place], [Area, CompanyUser] do |object|
         can?(:edit, object)
      end

      # Event Data
      can :edit_data, Event do |event|
       (event.unsent? && can?(:edit_unsubmitted_data, event)) ||
       (event.submitted? && can?(:edit_submitted_data, event)) ||
       (event.approved? && can?(:edit_approved_data, event)) ||
       (event.rejected? && can?(:edit_rejected_data, event))
      end

      can :view_data, Event do |event|
       (event.unsent? && can?(:view_unsubmitted_data, event)) ||
       (event.submitted? && can?(:view_submitted_data, event)) ||
       (event.approved? && can?(:view_approved_data, event)) ||
       (event.rejected? && can?(:view_rejected_data, event))
      end

      can :calendar, Event do |event|
        can?(:view_calendar, Event) && can?(:show, event)
      end

      cannot [:show, :edit], Event do |event|
        !user.current_company_user.accessible_campaign_ids.include?(event.campaign_id) ||
        !user.current_company_user.allowed_to_access_place?(event.place)
      end

      can [:select_brands, :add_brands], BrandPortfolio do |brand_portfolio|
        can?(:edit, brand_portfolio)
      end

      can :create, Brand do
        can?(:edit, BrandPortfolio)
      end

      # Team Members
      can [:add_members, :delete_member], Team do |team|
        can?(:edit, team)
      end

      can [:add, :list], ContactEvent if user.role.has_permission?(:create_contacts, Event)
      can [:new, :create], ContactEvent do |contact_event|
        can?(:show, contact_event.event) && can?(:create_contacts, contact_event.event)
      end
      can :destroy, ContactEvent do |contact_event|
        can?(:show, contact_event.event) && can?(:delete_contact, contact_event.event)
      end
      can :update, ContactEvent do |contact_event|
        can?(:show, contact_event.event) && can?(:edit_contacts, contact_event.event)
      end

      # Allow users to update kpis if have permissions to edit custom kpis or edit goals for the kpis,
      # the controller will decide what permissions can be modified based on those permissions
      can [:edit, :update], Kpi do |kpi|
        can?(:show, Campaign) &&
        (user.role.has_permission?(:edit_custom_kpi, Campaign) || user.role.has_permission?(:edit_kpi_goals, Campaign))
      end

      # Tasks permissions
      can :tasks, Event do |event|
        user.role.has_permission?(:index_tasks, Event) && can?(:show, event)
      end

      can :update, Task do |task|
        (user.role.has_permission?(:edit_task, Event) && can?(:show, task.event)) ||
        (user.role.has_permission?(:edit_my, Task) && task.company_user_id == user.current_company_user.id) ||
        (user.role.has_permission?(:edit_team, Task) && task.company_user_id != user.current_company_user.id && task.event.user_in_team?(user.current_company_user))
      end

      can [:deactivate, :activate], Task do |task|
        (user.role.has_permission?(:deactivate_task, Event) && can?(:show, task.event)) ||
        (user.role.has_permission?(:deactivate_my, Task) && task.company_user_id == user.current_company_user.id) ||
        (user.role.has_permission?(:deactivate_team, Task) && task.company_user_id != user.current_company_user.id && task.event.user_in_team?(user.current_company_user))
      end

      can :create, Task do |task|
        user.role.has_permission?(:create_task, Event) && can?(:show, task.event)
      end

      # Documents permissions
      can :documents, Event do |event|
        user.role.has_permission?(:index_documents, Event) && can?(:show, event)
      end

      can :create, AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'document' && user.role.has_permission?(:create_document, Event) && can?(:show, asset.attachable)
      end

      can [:deactivate, :activate], AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'document' && user.role.has_permission?(:deactivate_document, Event) && can?(:show, asset.attachable)
      end

      # Photos permissions
      can :photos, Event do |event|
        user.role.has_permission?(:index_photos, Event) && can?(:show, event)
      end

      can :create, AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'photo' && user.role.has_permission?(:create_photo, Event) && can?(:show, asset.attachable)
      end

      can [:deactivate, :activate], AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'photo' && user.role.has_permission?(:deactivate_photo, Event) && can?(:show, asset.attachable)
      end

      can :rate, AttachedAsset do |asset|
        asset.asset_type == 'photo' && user.role.has_permission?(:edit_rate, AttachedAsset)
      end

      can :view_rate, AttachedAsset do |asset|
        asset.asset_type == 'photo' && user.role.has_permission?(:view_rate, AttachedAsset)
      end

      # Event Expenses permissions
      can :expenses, Event do |event|
        user.role.has_permission?(:index_expenses, Event) && can?(:show, event)
      end

      can :update, EventExpense do |expense|
        user.role.has_permission?(:edit_expense, Event) && can?(:show, expense.event)
      end

      can :destroy, EventExpense do |expense|
        user.role.has_permission?(:deactivate_expense, Event) && can?(:show, expense.event)
      end

      can :create, EventExpense do |expense|
        user.role.has_permission?(:create_expense, Event) && can?(:show, expense.event)
      end

      # Surveys permissions
      can :surveys, Event do |event|
        user.role.has_permission?(:index_surveys, Event) && can?(:show, event)
      end

      can :update, Survey do |survey|
        user.role.has_permission?(:edit_survey, Event) && can?(:show, survey.event)
      end

      can :edit_surveys, Event do |event|
        (user.role.has_permission?(:edit_survey, Event) || user.role.has_permission?(:create_survey, Event)) && can?(:show, event)
      end

      can [:deactivate, :activate], Survey do |survey|
        user.role.has_permission?(:deactivate_survey, Event) && can?(:show, survey.event)
      end

      can :create, Survey do |survey|
        user.role.has_permission?(:create_survey, Event) && can?(:show, survey.event)
      end

      # Comments permissions
      can :comments, Event do |event|
        user.role.has_permission?(:index_comments, Event) && can?(:show, event)
      end
      can :comments, Task do |task|
        (user.role.has_permission?(:index_my_comments, Task) && task.company_user_id == user.current_company_user.id) ||
        (user.role.has_permission?(:index_team_comments, Task) && task.company_user_id != user.current_company_user.id && task.event.user_in_team?(user.current_company_user) )
      end

      can :update, Comment do |comment|
        user.role.has_permission?(:edit_comment, Event) && can?(:show, comment.commentable)
      end

      can :destroy, Comment do |comment|
        user.role.has_permission?(:deactivate_comment, Event) && can?(:show, comment.commentable)
      end

      can :create, Comment do |comment|
        (comment.commentable.is_a?(Event) && user.role.has_permission?(:create_comment, Event) && can?(:show, comment.commentable)) ||
        (comment.commentable.is_a?(Task) && user.role.has_permission?(:create_my_comment, Task) && comment.commentable.company_user_id == user.current_company_user.id) ||
        (comment.commentable.is_a?(Task) && user.role.has_permission?(:create_team_comment, Task) && comment.commentable.event.user_in_team?(user.current_company_user))
      end

      can :reject, Event do |event|
        can?(:approve, event)
      end
    end
  end
end
