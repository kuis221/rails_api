class ConfirmationsController < Devise::ConfirmationsController
  helper_method :resource

  def show
    unless resource.errors.empty?
      respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
    end
  end

  def update
    resource.updating_profile = true
    if resource.update_attributes(params[:user], as: :profile)
      @resource = resource_class.confirm_by_token(params[:confirmation_token])

      if @resource.errors.empty?
        set_flash_message(:notice, :confirmed) if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
      else
        respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
      end
    end
  end

  def resource
    @resource ||= resource_class.find_or_initialize_with_error_by(:confirmation_token, params[:confirmation_token])
  end
end