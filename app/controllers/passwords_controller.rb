class PasswordsController < Devise::PasswordsController
  def thanks
  end

  protected

  def after_sending_reset_password_instructions_path_for(_resource_name)
    passwords_thanks_path
  end
end
