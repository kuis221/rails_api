module TeamMembersHelper
  module InstanceMethods

    def delete_member
      resource.users.delete(team_member) if team_member
    end

    def new_member
      @users = company_users
      @teams = company_teams
      @roles = company_roles
      @users = @users.where(['id not in (?)', resource.users]) unless resource.users.empty?
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
        current_company.users.active.includes(:teams)
      end
      def company_teams
        current_company.teams.active.with_active_users(current_company).order('teams.name ASC')
      end
      def company_roles
        current_company.roles.active
      end
  end

  def self.included(receiver)
    receiver.send(:include,  InstanceMethods)
  end
end
