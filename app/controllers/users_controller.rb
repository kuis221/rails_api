class UsersController < InheritedResources::Base
  skip_before_filter :authenticate_user!, only: [:complete, :update_profile]
  append_before_filter :assert_auth_token_passed, only: :complete
  before_filter :ensure_no_user, only: [:complete, :update_profile]

  include DeactivableHelper

  load_and_authorize_resource except: [:complete, :update_profile]

  respond_to :js, only: [:new, :create, :edit, :update]

  custom_actions :collection => [:complete]

  respond_to_datatables do
    columns [
      {:attr => :last_name ,:column_name => 'users.last_name', :searchable => true, :clickable => false},
      {:attr => :first_name ,:column_name => 'users.first_name', :searchable => true, :clickable => false},
      {:attr => :city ,:column_name => 'users.city', :clickable => false},
      {:attr => :state_name ,:column_name => 'users.state', :clickable => false},
      {:attr => :country_name, :column_name => 'users.country', :clickable => false},
      {:attr => :email ,:column_name => 'users.email', :clickable => false},
      {:attr => :role_name ,:column_name => 'roles.name', :clickable => false},
      {:attr => :last_sign_in_at, :value => Proc.new{|user| user.last_sign_in_at.to_s(:full_friendly) if user.last_sign_in_at }, :column_name => 'users.last_sign_in_at', :clickable => false},
      {:attr => :aasm_state, :value => Proc.new{|user| user.aasm_state.capitalize }, :column_name => 'teams.name', :clickable => false}
    ]
    @editable  = true
    @deactivable = true
  end

  def dashboard
  end

  def update_profile
    @user = User.find_by_reset_password_token(params[:user][:reset_password_token])
    @user.updating_profile = true
    if @user.update_attributes(params[:user], as: :profile)
      @user.activate!
      sign_in(:user, @user)
      @user.send :generate_reset_password_token!
      flash[:notice] = 'You have successfully completed your profile'
      redirect_to root_path
    else
      render :complete
    end
  end

  def update
    update! do |success, failure|
      success.js do
        sign_in(@user, bypass: true) if @user.id == current_user.id
        render 'update'
      end
    end
  end

  def complete
    unless @user = User.find_by_reset_password_token(params[:auth_token])
      flash[:notice] = 'This url is not longer valid'
      redirect_to root_path
    end
  end

  def role_given?
    true
  end

  def as_role
    if params["id"] and current_user.id == resource.id
      { as: :profile }
    else
      {}
    end
  end

  protected

    def ensure_no_user
      if signed_in?
        flash[:notice] = 'You cannot access this page'
        redirect_to root_path
      end
    end

    # Check if a reset_password_token is provided in the request
    def assert_auth_token_passed
      if params[:auth_token].blank?
        set_flash_message(:error, :no_token)
        redirect_to new_session_path(resource_name)
      end
    end
end
