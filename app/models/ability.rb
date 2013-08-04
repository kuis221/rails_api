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

        can :manage, CompanyUser
        #can :manage, User, {:company_users => {:company_id => user.current_company.id}}

        can :manage, Campaign, :company_id => user.current_company.id
        can :manage, Kpi do |kpi|
          kpi.company_id == user.current_company.id || kpi.company_id.nil?
        end
        can :manage, Role, :company_id => user.current_company.id
        can :manage, Team, :company_id => user.current_company.id
        can :manage, Area, :company_id => user.current_company.id
        can :manage, Event, :company_id => user.current_company.id
        can :manage, BrandPortfolio, :company_id => user.current_company.id
        can [:index, :create], Brand
        can [:index, :create, :destroy, :show], Place
        can [:index, :show], Venue

        can :manage, DateRange, :company_id => user.current_company.id
        can :manage, DateItem, :date_range => {:company_id => user.current_company.id}
        can :create, DateItem

        can :manage, DayPart, :company_id => user.current_company.id
        can :manage, DayItem, :day_part => {:company_id => user.current_company.id}
        can :create, DayItem

        can :create, Task
        can :manage, Task, :event => {:company_id => user.current_company.id}

        can :manage, AttachedAsset
        can :manage, Document
      end
    end
  end
end
