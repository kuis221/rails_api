class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    # All users
    if user.id
      can :notifications, CompanyUser

      can :find_similar_kpi, Campaign do
        raise 'true'
        can?(:update, Campaign) || can?(:create, Campaign)
      end
    end

    # AdminUsers (logged in on Active Admin)
    if user.is_a?(AdminUser)
      # ActiveAdmin users
      can :manage, :all

    # Super Admin Users
    elsif  user.is_super_admin?

      # Super Admin Users can manage any object on the same company
      can do |action, subject_class, subject|
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

    # A logged in user
    elsif user.id
      can do |action, subject_class, subject|
        # Rails.logger.debug "\n\nAuthorizing #{action} on #{subject_class.to_s} => #{subject.inspect}\n"
        # Rails.logger.debug "\n\nuser.current_company ==> #{user.current_company.inspect}\n"
        user.role.permissions.select{|p| aliases_for_action(action).include?(p.action.to_sym)}.any? do |permission|
          permission.subject_class == subject_class.to_s &&
          (   subject.nil? ||
            ( subject.respond_to?(:company_id) && ((subject.company_id.nil? && [:create, :new].include?(action)) || subject.company_id == user.current_company.id) ) ||
            ( permission.subject_id.nil? || permission.subject_id == subject.id )
          )
        end
      end


      # Tasks permissions
      can :tasks, Event do |event|
        user.role.has_permission?(:index_tasks, Event) && can?(:show, event)
      end

      can :update, Task do |task|
        user.role.has_permission?(:edit_task, Event) && can?(:show, task.event)
      end

      can [:deactivate, :activate], Task do |task|
        user.role.has_permission?(:deactivate_task, Event) && can?(:show, task.event)
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

      can :update, Comment do |comment|
        user.role.has_permission?(:edit_comment, Event) && can?(:show, comment.commentable)
      end

      can :destroy, Comment do |comment|
        user.role.has_permission?(:deactivate_comment, Event) && can?(:show, comment.commentable)
      end

      can :create, Comment do |comment|
        user.role.has_permission?(:create_comment, Event) && can?(:show, comment.commentable)
      end
    end
  end
end
