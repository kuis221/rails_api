class UsersController < InheritedResources::Base
  skip_before_filter :authenticate_user!, only: [:complete, :update_profile]
  append_before_filter :assert_auth_token_passed, only: :complete
  before_filter :ensure_no_user, only: [:complete, :update_profile]

  include DeactivableHelper

  load_and_authorize_resource except: [:complete, :update_profile]

  respond_to :js, only: [:new, :create, :edit, :update]

  custom_actions :collection => [:complete]

  helper_method :roles

  respond_to_datatables do
    columns [
      {:attr => :last_name ,:column_name => 'users.last_name', :searchable => true},
      {:attr => :first_name ,:column_name => 'users.first_name', :searchable => true},
      {:attr => :city ,:column_name => 'users.city'},
      {:attr => :state_name ,:column_name => 'users.state'},
      {:attr => :country_name, :column_name => 'users.country'},
      {:attr => :email ,:column_name => 'users.email'},
      {:attr => :role_name ,:column_name => 'roles.name'},
      {:attr => :last_activity_at, :value => Proc.new{|user| user.last_activity_at.to_s(:full_friendly) if user.last_activity_at }, :column_name => 'users.last_activity_at'},
      {:attr => :active, :value => Proc.new{|user| user.active_status }}
    ]
    includes company_users: :role
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
    def begin_of_association_chain
      current_company
    end

    def build_resource
      if params[:user] and params[:user][:email] and @user = User.where(email: params[:user][:email]).first
        @user.attributes = {company_users_attributes: params[:user][:company_users_attributes]}
      else
        @user ||= User.new(params[:user])
        @user.company_users.build({company_id: current_company.id}, without_protection: true) if @user.company_users.empty?
      end
      @user.company_users.each{|cu| cu.company_id = current_company.id if cu.new_record? }
      @user
    end

    def roles
      @roles ||= current_company.roles
    end

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
