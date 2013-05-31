class ConfirmationsController < Devise::ConfirmationsController
  helper_method :resource

  def show
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

  def update
    user = resource
    user.updating_profile = true
    if user.update_attributes(params[:user], as: :profile)
      user = resource_class.confirm_by_token(params[:confirmation_token])
    end

    if user.errors.empty?
      set_flash_message(:notice, :confirmed) if is_navigational_format?
      sign_in(resource_name, user)
      respond_with_navigational(user){ redirect_to after_confirmation_path_for(resource_name, user) }
    else
      respond_with_navigational(user.errors, :status => :unprocessable_entity){ render :show }
    end
  end

  def resource
    @resource ||= resource_class.find_or_initialize_with_error_by(:confirmation_token, params[:confirmation_token])
  end
end