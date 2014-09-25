class InvitationsController < Devise::InvitationsController
  def new
    build_resource
    render :new
  end

  def edit
    unless resource.errors.empty?
      respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
    end

    if resource.country.nil? || resource.country.empty?
      location_info = Geocoder.search(request.remote_ip)
      if location = location_info.first and location.country != 'Reserved'
        country = Country.new(location.country_code)
        unless country.nil?
          resource.country = location.country_code
          country_states = country.states
          if country_states.key?(location.state_code)
            resource.state = location.state_code
          else
            # Try to find a state by name
            resource.state = country_states.select { |_k, v| v['name'] == location.state }.map { |k, _v| k }.first
          end
          resource.city = location.city
        end
      end
    end
  end

  def send_invite
    self.resource = User.find_by_email(params[:user][:email])
    if  resource.present? && resource.invited_to_sign_up?
      resource.invite!
      set_flash_message(:alert, :invitation_token_resent)
      flash[:alert] = flash[:alert].html_safe
      redirect_to after_sign_out_path_for(resource_name)
    else
      set_flash_message(:alert, :invalid_email)
      flash[:alert] = flash[:alert].html_safe
      redirect_to users_invitation_resend_path
    end
  end

  def create
    if params[:user] && params[:user][:email] && invited_user = User.where(["lower(users.email) = '%s'", params[:user][:email].downcase]).first
      if invited_user.company_users.select { |cu| cu.company_id == current_company.id }.size > 0
        self.resource = User.new(resource_params, as: :admin)
        resource.errors.add(:email, "This user with the email address #{params[:user][:email]} already exists. Email addresses must be unique.")
      else
        self.resource = invited_user
        resource.assign_attributes(inviting_user: true, company_users_attributes: resource_params[:company_users_attributes])
        if resource.save && resource.errors.empty?
          UserMailer.company_invitation(resource.id, current_company.id, current_user.id).deliver
        end
      end
    else
      self.resource = resource_class.invite!(resource_params, current_inviter)
    end
  end

  protected

  def build_resource(*_args)
    self.resource ||= resource_class.new
    self.resource.company_users.build if self.resource.company_users.empty?
    self.resource.company_users.each { |cu| cu.company_id = current_company.id if cu.new_record? }
    self.resource
  end

  def resource_params
    if user_params = super and user_signed_in?
      user_params[:inviting_user] = true
      user_params[:company_users_attributes] = { '0' => { role_id: nil } } if user_params[:company_users_attributes].nil? || user_params[:company_users_attributes].empty?
      user_params[:company_users_attributes].each { |_k, a| a[:company_id] = current_company.id }
    end
    user_params ||= params
    allowed = []
    if action_name == 'update'
      user_params[:accepting_invitation] = true
      allowed = [:first_name, :last_name, :email, :phone_number, :street_address, :unit_number, :zip_code, :password, :password_confirmation, :city, :state, :country, :time_zone, :invitation_token, :accepting_invitation]
    else
      allowed = [:first_name, :last_name, :email, :inviting_user, :accepting_invitation, { company_users_attributes: [:company_id, :role_id, { team_ids: [] }] }]
    end
    user_params.permit(*allowed)
  end

  def update_resource_params
    resource_params
  end

  def resource_from_invitation_token
    unless params[:invitation_token] && self.resource = resource_class.find_by_invitation_token(params[:invitation_token], true)
      set_flash_message(:alert, :invitation_token_invalid, reset_pass_url: new_password_path(resource_name))
      flash[:alert] = flash[:alert].html_safe
      redirect_to after_sign_out_path_for(resource_name)
    end
  end
end
