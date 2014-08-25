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
    alias_action :reject, :to => :approve
    alias_action :post_event_form, :update_post_event_form, :to => :view_event_form

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
      can [:notifications, :select_company, :dismiss_alert], CompanyUser

      # All users can update their own information
      can :update, CompanyUser, id: user.current_company_user.id

      can :super_update, CompanyUser do |cu|
        user.current_company_user.role.is_admin? || user.current_company_user.role.has_permission?(:update, CompanyUser)
      end

      can [:enable_campaigns, :disable_campaigns, :remove_campaign, :select_campaigns, :add_campaign], CompanyUser do |cu|
        can?(:edit, cu)
      end

      can [:update, :exclude_place, :include_place], AreasCampaign do |areas_campaign|
        can? :add_place, areas_campaign.campaign
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

      can [:new, :create], Kpi do |kpi|
        can?(:edit, Campaign)
      end

      # Special permission to allow editing global kpis (for goals setting)
      can [:edit, :update], Kpi do |kpi|
        kpi.company_id.nil? && can?(:edit, Campaign)
      end

      can :edit_data, Event

      can :access, :results

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

      can :index, Event do
        can?(:view_list, Event) || can?(:view_map, Event)
      end

      can :index, Marque

      can :form, Activity do
        can?(:create, Activity)
      end

      can :places, Campaign do |campaign|
        user.current_company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can :report, Campaign do |campaign|
        can?(:show_analysis, campaign) && user.current_company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can [:add_place, :remove_place], [Area, CompanyUser] do |object|
         can?(:edit, object)
      end

      can [:profile, :edit_communications], CompanyUser do |company_user|
        user.current_company_user.id == company_user.id
      end

      can [:verify_phone, :send_code], CompanyUser do |company_user|
        can?(:update, company_user)
      end

      # Custom Reports
      # can :manage, Report do |report|
      #   report.created_by_id == user.id
      # end

      can [:analysis], Venue do |venue|
        user.current_company_user.role.has_permission?(:show, Venue) && (
          user.current_company_user.role.has_permission?(:view_kpis, Venue) ||
          user.current_company_user.role.has_permission?(:view_score, Venue) ||
          user.current_company_user.role.has_permission?(:view_trends_day_week, Venue)
        )
      end

      can [:build, :preview, :rows], Report do |report|
        can? :edit, report
      end

      can [:rows, :filters], Report do |report|
        can?(:show, report) || can?(:edit, report)
      end

      # cannot :create, Report unless user.current_company_user.role.has_permission?(:create, Report)

      can :access, :results do
        user.current_company_user.role.has_permission?(:index, Report) ||
        user.current_company_user.role.has_permission?(:index_results, EventData) ||
        user.current_company_user.role.has_permission?(:index_results, Comment) ||
        user.current_company_user.role.has_permission?(:index_results, EventExpense) ||
        user.current_company_user.role.has_permission?(:index_results, Survey) ||
        user.current_company_user.role.has_permission?(:index_photo_results, AttachedAsset) ||
        user.current_company_user.role.has_permission?(:gva_report, Campaign) ||
        user.current_company_user.role.has_permission?(:event_status, Campaign)
      end

      can [:build, :preview, :update], Report do |report|
        user.current_company_user.role.has_permission?(:create, Report) &&
        report.created_by_id == user.id
      end

      cannot [:edit, :update, :show, :share], Report do |report|
        report.created_by_id != user.id &&
        Report.accessible_by_user(user.current_company_user).where(id: report.id).none?
      end

      can [:share_form], Report do |report|
        user.current_company_user.role.has_permission?(:share, Report) &&
        Report.accessible_by_user(user.current_company_user).where(id: report.id).any?
      end

      # Event permissions
      can :access, Event do |event|
        user.current_company_user.company_id == event.company_id &&
        user.current_company_user.accessible_campaign_ids.include?(event.campaign_id) &&
        user.current_company_user.allowed_to_access_place?(event.place)
      end

      # Event Data
      can :edit_data, Event do |event|
        can?(:access, event) && (
          (event.unsent? && can?(:edit_unsubmitted_data, event)) ||
          (event.submitted? && can?(:edit_submitted_data, event)) ||
          (event.approved? && can?(:edit_approved_data, event)) ||
          (event.rejected? && can?(:edit_rejected_data, event))
        )
      end

      can :view_data, Event do |event|
       (event.unsent? && can?(:view_unsubmitted_data, event)) ||
       (event.submitted? && can?(:view_submitted_data, event)) ||
       (event.approved? && can?(:view_approved_data, event)) ||
       (event.rejected? && can?(:view_rejected_data, event))
      end

      can :view_or_edit_data, Event do |event|
        can?(:view_data, event) || can?(:edit_data, event)
      end

      can :calendar, Event do |event|
        can?(:view_calendar, Event) && can?(:show, event)
      end

      cannot :show, Event do |event|
        cannot?(:access, event)
      end

      cannot :activate, Tag do |tag|
         !user.current_company_user.role.has_permission?(:activate, Tag)
      end

      can :gva_report_campaign, Campaign do |campaign|
        can?(:gva_report, Campaign) &&
        user.current_company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can :event_status_report_campaign, Campaign do |campaign|
        can?(:event_status, Campaign) &&
        user.current_company_user.accessible_campaign_ids.include?(campaign.id)
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

      cannot [:approve, :reject, :submit,
              :view_members, :add_members, :delete_member,
              :view_contacts, :create_contacts, :edit_contacts, :delete_contact], Event do |event|
        cannot?(:show, event)
      end

      can(:show, Contact) do |contact|
        user.current_company_user.company_id == contact.company_id
      end

      can [:add, :list], ContactEvent do
        user.role.has_permission?(:create_contacts, Event)
      end
      can [:new, :create], ContactEvent do |contact_event|
        can?(:show, contact_event.event) && can?(:create_contacts, contact_event.event)
      end
      can :destroy, ContactEvent do |contact_event|
        can?(:show, contact_event.event) && can?(:delete_contact, contact_event.event)
      end
      can :update, ContactEvent do |contact_event|
        can?(:show, contact_event.event) && can?(:edit_contacts, contact_event.event)
      end
      can :update, Contact do |contact|
        user.current_company_user.company_id == contact.company_id &&
        user.current_company_user.role.has_permission?(:edit_contacts, Event)
      end

      # Allow users to create kpis if have permissions to create custom kpis,
      # the controller will decide what permissions can be modified based on those permissions
      can [:new, :create], Kpi do |kpi|
        can?(:edit, Campaign) && user.role.has_permission?(:create_custom_kpis, Campaign)
      end

      can [:select_kpis], Campaign do |campaign|
        can?(:create_custom_kpis, campaign) || can?(:activate_kpis, campaign)
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
        (user.role.has_permission?(:create_task, Event) && can?(:show, task.event)) ||
        user.role.has_permission?(:create_my, Task) || user.role.has_permission?(:create_team, Task)
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

      can :activate, Tag do
        can?(:create, Tag)
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

      can :view_promo_hours_data, Campaign do |campaign|
        user.current_company_user.accessible_campaign_ids.include?(campaign.id)
      end
    end
  end
end
