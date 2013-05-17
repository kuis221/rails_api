class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.is_a?(AdminUser)
      # ActiveAdmin users
      can :manage, :all
    else
      if user.id
        # Basic permissions check, all users can manage resources within
        # they same company

        can :manage, User
        can :manage, CompanyUser
        #can :manage, User, {:company_users => {:company_id => user.current_company.id}}

        can :manage, Campaign, :company_id => user.current_company.id
        can :manage, Team, :company_id => user.current_company.id
        can :manage, Event, :company_id => user.current_company.id

        can :create, Task
        can :manage, Task, :event => {:company_id => user.current_company.id}

        can :manage, Document
      end
    end
  end
end
