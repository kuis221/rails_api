class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    # Basic permissions check, all users can manage resources within
    # they same company
    can :manage, User, :company_id => user.company_id
    can :manage, Campaign, :company_id => user.company_id
    can :manage, Team, :company_id => user.company_id
    can :manage, Event, :company_id => user.company_id

    can :create, Task
    can :manage, Task, :event => {:company_id => user.company_id}
  end
end
