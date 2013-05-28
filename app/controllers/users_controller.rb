class UsersController < FilteredController
  skip_before_filter :authenticate_user!, only: [:complete, :update_profile]
  append_before_filter :assert_auth_token_passed, only: :complete
  before_filter :ensure_no_user, only: [:complete, :update_profile]

  include DeactivableHelper

  load_and_authorize_resource except: [:complete, :update_profile, :index]

  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :json, only: [:index]

  has_scope :with_text
  has_scope :by_teams
  has_scope :by_campaigns

  custom_actions :collection => [:complete]

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

    def begin_of_association_chain
      current_company
    end

    def collection_to_json
      collection.map{|user| {
        :id => user.id,
        :last_name => user.last_name,
        :first_name => user.first_name,
        :city => user.city,
        :state => user.state_name,
        :country => user.country_name,
        :email => user.email,
        :role => user.role_name,
        :last_sign_in_at => user.last_sign_in_at.try(:to_s,:full_friendly),
        :status => user.aasm_state.capitalize,
        :active => user.active?,
        :links => {
            edit: edit_user_path(user),
            activate: activate_user_path(user),
            deactivate: deactivate_user_path(user),
            delete: delete_member_path(user)
        }
      }}
    end

    def delete_member_path(user)
      path = nil
      path = delete_member_team_path(params[:by_teams], member_id: user.id) if params.has_key?(:by_teams) && params[:by_teams]
      path = delete_member_campaign_path(params[:by_campaigns], member_id: user.id) if params.has_key?(:by_campaigns) && params[:by_campaigns]
      path
    end

    def sort_options
      {
        'last_name' => { :order => 'users.last_name' },
        'first_name' => { :order => 'users.first_name' },
        'city' => { :order => 'users.city' },
        'state' => { :order => 'users.state' },
        'country' => { :order => 'users.country' },
        'email' => { :order => 'users.active' },
        'role' => { :order => 'roles.name' },
        'last_login' => { :order => 'users.last_sign_in_at' },
        'status' => { :order => 'users.active' }
      }
    end

    # Check if a reset_password_token is provided in the request
    def assert_auth_token_passed
      if params[:auth_token].blank?
        set_flash_message(:error, :no_token)
        redirect_to new_session_path(resource_name)
      end
    end
end
