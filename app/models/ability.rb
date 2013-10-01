class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    # All users
    if user.id
      can :notifications, CompanyUser
    end

    if user.is_a?(AdminUser)
      # ActiveAdmin users
      can :manage, :all
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
    elsif user.id
      can do |action, subject_class, subject|
        Rails.logger.debug "CHECKING: #{action} with aliases #{aliases_for_action(action).inspect} on #{subject_class} ::> #{subject.inspect}"
        user.role.permissions.select{|p| aliases_for_action(action).include?(p.action.to_sym)}.any? do |permission|
          permission.subject_class == subject_class.to_s &&
          (   subject.nil? ||
            ( subject.respond_to?(:company_id) && ((subject.company_id.nil? && [:create, :new].include?(action)) || subject.company_id == user.current_company.id) ) ||
            ( permission.subject_id.nil? || permission.subject_id == subject.id )
          )
        end
      end
    end
  end
end
