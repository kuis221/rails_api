class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    alias_action :activate, to: :deactivate
    alias_action :new_member, to: :add_members
    alias_action :new_member, to: :add_staff
    alias_action :add_kpi, to: :activate_kpis
    alias_action :remove_kpi, to: :activate_kpis
    alias_action :add_activity_type, to: :activate_kpis
    alias_action :remove_activity_type, to: :activate_kpis
    alias_action :reject, to: :approve
    alias_action :post_event_form, :update_post_event_form, to: :view_event_form
    alias_action :rate, to: :edit_rate

    company_user = user.current_company_user if user.id && !user.is_a?(AdminUser)

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
      can :event_dates, Campaign
      can [:notifications, :select_company, :dismiss_alert], CompanyUser

      # All users can update their own information
      can :update, CompanyUser, id: company_user.id

      can :super_update, CompanyUser do |_cu|
        company_user.role.is_admin? || company_user.role.has_permission?(:update, CompanyUser)
      end

      can [:enable_campaigns, :disable_campaigns, :remove_campaign, :select_campaigns, :add_campaign], CompanyUser do |cu|
        can?(:edit, cu)
      end

      can [:update, :exclude_place, :include_place, :new_place, :add_place], AreasCampaign do |areas_campaign|
        can? :add_place, areas_campaign.campaign
      end

      can :cities, Area
    end


    # AdminUsers (logged in on Active Admin)
    if user.is_a?(AdminUser)
      # ActiveAdmin users
      can :manage, :all

    # Super Admin Users
    elsif user.is_super_admin?
      can :manage, :dashboard

      # Analysis reports
      can :access, :trends_report

      # Super Admin Users can manage any object on the same company
      can do |action, subject_class, subject|
        Rails.logger.debug "Checking #{action} on #{subject_class} :: #{subject}"
        subject.nil? || (subject.respond_to?(:company_id) && ((subject.company_id.nil? && [:create, :new].include?(action)) || subject.company_id == user.current_company.id))
      end

      cannot do |_action, subject_class, _subject|
        [Company].include?(subject_class)
      end

      can [:new, :create], Kpi do |_kpi|
        can?(:edit, Campaign)
      end

      # Special permission to allow editing global kpis (for goals setting)
      can [:edit, :update], Kpi do |kpi|
        kpi.company_id.nil? && can?(:edit, Campaign)
      end

      can :edit_data, Event

      can :access, [:results, :brand_ambassadors, :analysis]

    # A logged in user
    elsif user.id
      role = company_user.role
      can do |action, subject_class, subject|
        Rails.logger.debug "Checking #{action} on #{subject_class} :: #{subject}"
        user.role.cached_permissions.select { |p| p['mode'] != 'none' && aliases_for_action(action).map(&:to_s).include?(p['action'].to_s) }.any? do |permission|
          (permission['subject_class'] == subject_class.to_s) &&
          (subject.nil? || permission['mode'] == 'all' || !subject.respond_to?(:campaign_id) || (action.to_s == 'new' && subject.new_record?)  || company_user.accessible_campaign_ids.include?(subject.campaign_id)) &&
          (subject.nil? ||
            (subject.respond_to?(:company_id) && ((subject.company_id.nil? && [:create, :new].include?(action)) || subject.company_id == user.current_company.id)) ||
            (!subject.respond_to?(:company_id) && (permission['subject_id'].nil? || (subject.respond_to?(:id) ? permission['subject_id'] == subject.id : permission['subject_id'] == subject.to_s)))
          )
        end
      end

      can :search, Place

      can :index, Event do
        can?(:view_list, Event) || can?(:view_map, Event) || can?(:view_calendar, Event)
      end

      can :index, Marque

      can [:new, :form, :thanks], Activity do
        can?(:create, Activity) ||
        role.has_permission?(:create_invite, Event) ||
        role.has_permission?(:create_invite, Venue)
      end

      can :places, Campaign do |campaign|
        company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can :report, Campaign do |campaign|
        can?(:show_analysis, campaign) && company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can [:add_place, :remove_place], [Area, CompanyUser] do |object|
        can?(:edit, object)
      end

      can :create, Invite do |invite|
        role.has_permission?(:create_invite, Event) ||
        role.has_permission?(:create_invite, Venue)
      end

      can :update, Invite do |invite|
        role.has_permission?(:edit_invite, Event) ||
        role.has_permission?(:edit_invite, Venue)
      end

      can [:profile, :edit_communications, :filter_settings], CompanyUser do |company_user|
        company_user.id == company_user.id
      end

      can [:verify_phone, :send_code], CompanyUser do |company_user|
        can?(:update, company_user)
      end

      can :resend_invite, CompanyUser do |company_user|
        can?(:index, company_user)
      end

      can :export_fieldable, Campaign do |campaign|
        can?(:view_event_form, campaign)
      end

      can :export_fieldable, ActivityType do |activity_type|
        can?(:show, activity_type)
      end

      can :export_fieldable, Event do |event|
        can?(:view_data, event) || can?(:edit_data, event)
      end

      can :export_fieldable, Activity do |activity|
        can?(:show, activity)
      end

      can :update, DataExtract do |extract|
        extract.created_by_id == user.id
      end

      # Custom Reports
      # can :manage, Report do |report|
      #   report.created_by_id == user.id
      # end

      can [:analysis], Venue do |_venue|
        company_user.role.has_permission?(:show, Venue) && (
          company_user.role.has_permission?(:view_kpis, Venue) ||
          company_user.role.has_permission?(:view_score, Venue) ||
          company_user.role.has_permission?(:view_trends_day_week, Venue)
        )
      end

      can [:build, :preview, :rows], Report do |report|
        can? :edit, report
      end

      can [:rows, :filters], Report do |report|
        can?(:show, report) || can?(:edit, report)
      end

      # cannot :create, Report unless company_user.role.has_permission?(:create, Report)

      can :access, :results do
        company_user.role.has_permission?(:index, Report) ||
        company_user.role.has_permission?(:index_results, EventData) ||
        company_user.role.has_permission?(:index_results, Comment) ||
        company_user.role.has_permission?(:index_results, EventExpense) ||
        company_user.role.has_permission?(:index_results, Survey) ||
        company_user.role.has_permission?(:index_photo_results, AttachedAsset)
      end

      can :access, :analysis do
        can?(:index, Analysis) ||
        can?(:attendance, Event) ||
        can?(:view_gva_report, Campaign) ||
        can?(:view_event_status, Campaign) ||
        can?(:access, :trends_report)
      end

      can :access, :brand_ambassadors do
        company_user.role.has_permission?(:list, BrandAmbassadors::Visit) ||
        company_user.role.has_permission?(:calendar, BrandAmbassadors::Visit) ||
        company_user.role.has_permission?(:index, BrandAmbassadors::Document)
      end

      can [:destroy, :move, :edit, :update], BrandAmbassadors::Document do |document|
        can? :create, document
      end

      can :index, BrandAmbassadors::Visit do
        company_user.role.has_permission?(:list, BrandAmbassadors::Visit) ||
        company_user.role.has_permission?(:calendar, BrandAmbassadors::Visit)
      end

      can :show, AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && can?(:show, asset.attachable)
      end

      can [:build, :preview, :update], Report do |report|
        company_user.role.has_permission?(:create, Report) &&
        report.created_by_id == user.id
      end

      cannot [:edit, :update, :show, :share], Report do |report|
        report.created_by_id != user.id &&
        Report.accessible_by_user(company_user).where(id: report.id).none?
      end

      can [:share_form], Report do |report|
        company_user.role.has_permission?(:share, Report) &&
        Report.accessible_by_user(company_user).where(id: report.id).any?
      end

      # Event permissions
      can :access, Event do |event|
        company_user.company_id == event.company_id &&
        company_user.allowed_to_access_place?(event.place)
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

      cannot [:show], Event do |event|
        cannot?(:access, event)
      end

      can :gva_report_campaign, Campaign do |campaign|
        can?(:view_gva_report, Campaign) &&
        company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can :view_gva_report, Campaign if can?(:gva_report_campaigns, Campaign) ||
                                        can?(:gva_report_places, Campaign) ||
                                        can?(:gva_report_users, Campaign)

      can :map, Event if role.has_permission?(:view_map, Event)

      can [:select_areas, :add_areas, :delete_area], Venue do |venue|
        can?(:show, venue) &&
        company_user.role.has_permission?(:update, Area)
      end

      can :event_status_report_campaign, Campaign do |campaign|
        can?(:view_event_status, Campaign) &&
        company_user.accessible_campaign_ids.include?(campaign.id)
      end

      can :view_event_status, Campaign if can?(:event_status_campaigns, Campaign) ||
                                          can?(:event_status_places, Campaign) ||
                                          can?(:event_status_users, Campaign)

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

      # Team Members
      can [:add_members, :delete_member], Campaign do |campaign|
        can?(:show, campaign)
      end

      cannot [:approve, :unapprove, :reject, :submit,
              :view_members, :add_members, :delete_member,
              :view_contacts, :create_contacts, :edit_contacts, :delete_contact], Event do |event|
        cannot?(:show, event)
      end

      can(:show, Contact) do |contact|
        company_user.company_id == contact.company_id
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
        company_user.company_id == contact.company_id &&
        company_user.role.has_permission?(:edit_contacts, Event)
      end

      # Allow users to create kpis if have permissions to create custom kpis,
      # the controller will decide what permissions can be modified based on those permissions
      can [:new, :create], Kpi do |_kpi|
        can?(:edit, Campaign) && user.role.has_permission?(:create_custom_kpis, Campaign)
      end

      can [:select_kpis], Campaign do |campaign|
        can?(:create_custom_kpis, campaign) || can?(:activate_kpis, campaign)
      end

      can :index, Kpi do
        can?(:view_event_form, Campaign)
      end

      # Allow users to update kpis if have permissions to edit custom kpis or edit goals for the kpis,
      # the controller will decide what permissions can be modified based on those permissions
      can [:edit, :update], Kpi do |_kpi|
        can?(:show, Campaign) &&
        (user.role.has_permission?(:edit_custom_kpi, Campaign) || user.role.has_permission?(:edit_kpi_goals, Campaign))
      end

      # Tasks permissions
      can :tasks, Event do |event|
        user.role.has_permission?(:index_tasks, Event) &&
        (user.role.permission_for(:index_documents, Event).mode == 'all' ||
         company_user.accessible_campaign_ids.include?(event.campaign_id)) &&
        can?(:show, event)
      end

      can :invites, Event do |event|
        user.role.has_permission?(:index_invites, Event) &&
        company_user.accessible_campaign_ids.include?(event.campaign_id) &&
        can?(:show, event)
      end

      can :invites, Venue do |venue|
        user.role.has_permission?(:index_invites, Venue) &&
        can?(:show, venue)
      end

      can :update, Task do |task|
        (user.role.has_permission?(:edit_task, Event) && can?(:show, task.event)) ||
        (user.role.has_permission?(:edit_my, Task) && task.company_user_id == company_user.id) ||
        (user.role.has_permission?(:edit_team, Task) && task.company_user_id != company_user.id && task.event.user_in_team?(company_user))
      end

      can [:deactivate, :activate], Task do |task|
        (user.role.has_permission?(:deactivate_task, Event) && can?(:show, task.event)) ||
        (user.role.has_permission?(:deactivate_my, Task) && task.company_user_id == company_user.id) ||
        (user.role.has_permission?(:deactivate_team, Task) && task.company_user_id != company_user.id && task.event.user_in_team?(company_user))
      end

      can :create, Task do |task|
        (user.role.has_permission?(:create_task, Event) && can?(:show, task.event)) ||
        user.role.has_permission?(:create_my, Task) || user.role.has_permission?(:create_team, Task)
      end

      # Documents permissions
      can :documents, Event do |event|
        user.role.has_permission?(:index_documents, Event) &&
        (user.role.permission_for(:index_documents, Event).mode == 'all' ||
         company_user.accessible_campaign_ids.include?(event.campaign_id)) &&
        can?(:show, event)
      end

      # if user.role.has_permission?(:create_photo, Event) || user.role.has_permission?(:create_document, Event)
      #   can [:new, :create], AttachedAsset
      # end
      can :create, AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && can?(:show, asset.attachable) && (
          ( asset.asset_type == 'document' && can?(:create_document, asset.attachable) ) ||
          ( asset.asset_type == 'photo' && can?(:create_photo, asset.attachable) )
        )
      end

      can [:deactivate, :activate], AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'document' &&
        user.role.has_permission?(:deactivate_document, Event) &&
        can?(:show, asset.attachable)
      end

      # Photos permissions
      can :photos, Event do |event|
        user.role.has_permission?(:index_photos, Event) &&
        (user.role.permission_for(:index_photos, Event).mode == 'all' ||
         company_user.accessible_campaign_ids.include?(event.campaign_id)) &&
         can?(:show, event)
      end

      can [:deactivate, :activate], AttachedAsset do |asset|
        asset.attachable.is_a?(Event) && asset.asset_type == 'photo' &&
        user.role.has_permission?(:deactivate_photo, Event) &&
        (user.role.permission_for(:deactivate_photo, Event).mode == 'all' ||
         company_user.accessible_campaign_ids.include?(asset.attachable.campaign_id)) &&
        can?(:show, asset.attachable)
      end

      [:edit_rate, :view_rate, :index_tag, :create_tag, :activate_tag, :remove_tag].each do |action|
        cannot action, AttachedAsset do |asset|
          asset.asset_type == 'photo' &&
          (!user.role.has_permission?(action, AttachedAsset) ||
           (user.role.permission_for(action, AttachedAsset).mode == 'campaigns' &&
           !company_user.accessible_campaign_ids.include?(asset.attachable.campaign_id))
          )
        end
      end

      # Event Expenses permissions
      can :expenses, Event do |event|
        user.role.has_permission?(:index_expenses, Event) &&
        (user.role.permission_for(:index_expenses, Event).mode == 'all' ||
         company_user.accessible_campaign_ids.include?(event.campaign_id)) &&
        can?(:show, event)
      end

      can :update, EventExpense do |expense|
        user.role.has_permission?(:edit_expense, Event) &&
        (user.role.permission_for(:edit_expense, Event).mode == 'all' ||
         company_user.accessible_campaign_ids.include?(expense.event.campaign_id)) &&
        can?(:show, expense.event)
      end

      can :destroy, EventExpense do |expense|
        user.role.has_permission?(:deactivate_expense, Event) &&
        (user.role.permission_for(:deactivate_expense, Event).mode == 'all' ||
         company_user.accessible_campaign_ids.include?(expense.event.campaign_id)) &&
        can?(:show, expense.event)
      end

      can :create, EventExpense do |expense|
        user.role.has_permission?(:create_expense, Event) &&
        (user.role.permission_for(:create_expense, Event).mode == 'all' ||
         company_user.accessible_campaign_ids.include?(expense.event.campaign_id)) &&
        can?(:show, expense.event)
      end

      can :split, EventExpense do |expense|
       (expense.new_record? && can?(:create_expense, expense.event)) ||
       (expense.persisted? && can?(:edit_expense, expense.event))
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
        (user.role.has_permission?(:index_my_comments, Task) && task.company_user_id == company_user.id) ||
        (user.role.has_permission?(:index_team_comments, Task) && task.company_user_id != company_user.id && task.event.user_in_team?(company_user))
      end

      can :update, Comment do |comment|
        user.role.has_permission?(:edit_comment, Event) && can?(:show, comment.commentable)
      end

      can :destroy, Comment do |comment|
        user.role.has_permission?(:deactivate_comment, Event) && can?(:show, comment.commentable)
      end

      can :create, Comment do |comment|
        (comment.commentable.is_a?(Event) && user.role.has_permission?(:create_comment, Event) && can?(:show, comment.commentable)) ||
        (comment.commentable.is_a?(Task) && user.role.has_permission?(:create_my_comment, Task) && comment.commentable.company_user_id == company_user.id) ||
        (comment.commentable.is_a?(Task) && user.role.has_permission?(:create_team_comment, Task) && comment.commentable.event.user_in_team?(company_user))
      end

      can :view_promo_hours_data, Campaign do |campaign|
        company_user.accessible_campaign_ids.include?(campaign.id)
      end
    end
  end
end
