module TeamMembersHelper

  module InstanceMethods

    def delete_member
      if member
        user = member.dup
        if resource.users.delete(member)
          users = user.id
        end
      elsif team
        team_users = team.user_ids
        if resource.teams.delete(team)
          resource.solr_index
          assigned_users = resource.user_ids
          users = team_users - assigned_users
        end
      end
    end

    def new_member
      @teams = company_teams
      @roles = company_roles
      @users = company_users
      @users = @users.where(['company_users.id not in (?)', resource.users]) unless resource.users.empty?
    end

    def add_members
      @team_id = @member_id = nil
      if params[:member_id]
        @member_id = params[:member_id]
        member =  company_users.find(params[:member_id])
        unless resource.user_ids.include?(member.id)
          resource.update_attributes(user_ids: resource.user_ids + [member.id])
        end
      elsif params[:team_id]
        @team_id = params[:team_id]
        unless resource.teams.where(id: @team_id).first
          team = company_teams.find(@team_id)
          resource.teams << team
          resource.solr_index
        end
      end
    end

    private
      def member
        begin
          @member = resource.users.find(params[:member_id])
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end

      def team
        begin
          @team = resource.teams.find(params[:team_id]) if resource.respond_to?(:teams)
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end

      def company_users
        @company_users ||= CompanyUser.active.scoped_by_company_id(current_company).includes(:user).where('users.invitation_accepted_at is not null').order('users.last_name ASC')
      end
      def company_teams
        @company_teams ||= current_company.teams.active.order('teams.name ASC')
      end
      def company_roles
        @company_roles ||= current_company.roles.active.order('roles.name ASC')
      end

      def assignable_teams
        @assignable_teams ||= company_teams.with_active_users(current_company).order('teams.name ASC').select do |team|
          !resource.team_ids.include?(team.id)
        end
      end
  end

  def self.extended(receiver)
    receiver.send(:include,  InstanceMethods)
    receiver.helper_method :assignable_teams
  end
end
