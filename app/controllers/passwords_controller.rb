class PasswordsController < Devise::PasswordsController
  def thanks
  end
	
  # POST /resource/password
  def create
    self.resource = User.find_by_email(resource_params[:email])
    if self.resource.blank?
      self.resource = resource_class.send_reset_password_instructions(resource_params)
      respond_with(resource)
    else
      if self.resource.is_fully_valid?
        self.resource = resource_class.send_reset_password_instructions(resource_params)
        yield resource if block_given?

        if successfully_sent?(resource)
          respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
        else
          respond_with(resource)
        end
      else
        self.resource.invite!
        set_flash_message(:alert, :invitation_token_resent)
        flash[:alert] = flash[:alert].html_safe
        redirect_to after_sign_out_path_for(resource_name)
      end
    end
  end


  protected
  def after_sending_reset_password_instructions_path_for(resource_name)
    passwords_thanks_path
  end

end