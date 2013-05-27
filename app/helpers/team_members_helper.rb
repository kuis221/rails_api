module TeamMembersHelper
  module InstanceMethods

    def delete_member
      if team_member
        user_id = team_member.id
        if resource.users.delete(team_member)
          if resource.is_a?(Event)
            Task.scoped_by_event_id(resource).scoped_by_user_id(user_id).update_all(user_id: nil)
          end
        end
      end
    end

    def new_member
      @teams = company_teams
      @assignable_teams = company_teams.with_active_users(current_company).order('teams.name ASC')
      @roles = company_roles
      @users = company_users
      @users = @users.where(['users.id not in (?)', resource.users]) unless resource.users.empty?
    end

    def add_members
      @members = []
      if params[:member_id]
        @members = [company_users.find(params[:member_id])]
      elsif params[:team_id]
        @members = company_teams.find(params[:team_id]).users.active.all
      end

      @members.each do |member|
        unless resource.users.where(id: member.id).first
          resource.users << member
        end
      end
    end

    private
      def team_member
        begin
          @team_member = resource.users.find(params[:member_id])
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end

      def company_users
        current_company.users.active_in_company(current_company).order('users.last_name ASC')
      end
      def company_teams
        current_company.teams.active.order('teams.name ASC')
      end
      def company_roles
        current_company.roles.active.order('roles.name ASC')
      end
  end

  def self.included(receiver)
    receiver.send(:include,  InstanceMethods)
  end
end
