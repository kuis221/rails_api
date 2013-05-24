module TeamMembersHelper
  module InstanceMethods

    def delete_member
      resource.users.delete(team_member) if team_member
    end

    def new_member
      @teams = company_teams
      @assignable_teams = company_teams.with_active_users.order('teams.name ASC')
      @roles = company_roles
      @users = company_users
      @users = @users.where(['id not in (?)', resource.users]) unless resource.users.empty?

      Rails.logger.debug "@teams = #{@teams.inspect}"
      Rails.logger.debug "@roles = #{@roles.inspect}"
      Rails.logger.debug "@users roles = #{@users.map(&:role_id).inspect}"
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
        current_company.users.active.order('users.last_name ASC')
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
