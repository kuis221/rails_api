class UsersController < InheritedResources::Base
  skip_before_filter :authenticate_user!, only: [:complete, :update_profile]
  append_before_filter :assert_auth_token_passed, only: :complete

  respond_to :js, only: [:new, :create, :edit, :update]

  custom_actions :resource => [:deactivate], :collection => [:complete]

  helper_method :user_groups

  respond_to_datatables do
    columns [
      {:attr => :first_name ,:column_name => 'users.first_name', :searchable => true},
      {:attr => :last_name ,:column_name => 'users.last_name', :searchable => true},
      {:attr => :email ,:column_name => 'users.email'}
    ]
    @editable  = true
    @deactivable = true
  end

  def deactivate
    if resource.active?
      resource.deactivate!
    else
      resource.activate!
    end
  end

  def dashboard
  end

  def update_profile
    @user = User.find_by_reset_password_token(params[:user][:reset_password_token])
    @user.updating_profile = true
    if @user.update_attributes(params[:user], as: :profile)
      sign_in(:user, @user)
      @user.send :generate_reset_password_token!
      flash[:notice] = 'Your info have successfully updated'
      redirect_to root_path
    else
      render :complete
    end
  end

  def complete
    unless @user = User.find_by_reset_password_token(params[:auth_token])
      flash[:notice] = 'This url is not longer valid'
      redirect_to root_path
    end
  end

  protected
    def user_groups
      @user_groups ||= UserGroup.all
    end

    # Check if a reset_password_token is provided in the request
    def assert_auth_token_passed
      if params[:auth_token].blank?
        set_flash_message(:error, :no_token)
        redirect_to new_session_path(resource_name)
      end
    end
end
