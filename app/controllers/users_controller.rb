class UsersController < InheritedResources::Base
  skip_before_filter :authenticate_user!, only: [:complete, :update_profile]
  append_before_filter :assert_auth_token_passed, only: :complete
  before_filter :ensure_no_user, only: [:complete, :update_profile]

  load_and_authorize_resource

  respond_to :js, only: [:new, :create, :edit, :update]

  custom_actions :resource => [:deactivate], :collection => [:complete]

  helper_method :user_groups

  respond_to_datatables do
    columns [
      {:attr => :last_name ,:column_name => 'users.last_name', :searchable => true},
      {:attr => :first_name ,:column_name => 'users.first_name', :searchable => true},
      {:attr => :city ,:column_name => 'users.city'},
      {:attr => :state_name ,:column_name => 'users.state'},
      {:attr => :country_name, :column_name => 'users.country'},
      {:attr => :email ,:column_name => 'users.email'},
      {:attr => :user_group_name ,:column_name => 'user_groups.name'},
      {:attr => :teams, :value => Proc.new{|user| user.teams.active.map(&:name).join ', ' }, :column_name => 'teams.name'},
      {:attr => :aasm_state, :value => Proc.new{|user| user.aasm_state.capitalize }, :column_name => 'teams.name'}
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
      @user.activate!
      flash[:notice] = 'You have successfully completed your profile'
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
