class InvitationsController < Devise::InvitationsController
  def edit
    unless resource.errors.empty?
      respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
    end
    # All countries with US at the begining
    @countries = [
        [].tap{|arr| c= Country.find_country_by_name('United States'); arr.push c.name; arr.push c.alpha2},
        ["-------------------", ""]
      ] +
      Country.all
  end

  def create
    if params[:user] and params[:user][:email] and self.resource = User.where(email: params[:user][:email]).first
      self.resource.update_attributes({inviting_user: true, company_users_attributes: resource_params[:company_users_attributes]}, as: User.inviter_role(current_inviter))
      if self.resource.save
        UserMailer.company_invitation(self.resource, current_company, current_user).deliver
      end
    else
      self.resource = resource_class.invite!(resource_params, current_inviter)
    end
  end

  protected
    def build_resource(*args)
      self.resource ||= super
      self.resource.company_users.new if self.resource.company_users.size == 0
      self.resource.company_users.each{|cu| cu.company_id = current_company.id if cu.new_record? }
      self.resource
    end

    def resource_params
      if user_params = super and user_signed_in?
        user_params[:inviting_user] = true
        user_params[:company_users_attributes] ||= {"0" => {:role_id => nil}}
        user_params[:company_users_attributes].each{|k,a| a[:company_id] = current_company.id}
      end
      user_params
    end
end