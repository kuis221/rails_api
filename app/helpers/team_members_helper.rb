module TeamMembersHelper
  module InstanceMethods

    def delete_member
      resource.users.delete(team_member) if team_member
    end

    def new_member
      @users = company_users
      @users = @users.where(['id not in (?)', resource.users]) unless resource.users.empty?
    end

    def add_member
      @member = company_users.find(params[:member_id])
      unless resource.users.where(id: @member.id).first
        resource.users << @member
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
        current_company.users.active
      end
  end

  def self.included(receiver)
    receiver.send(:include,  InstanceMethods)
  end
end
