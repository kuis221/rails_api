class UsersController < FilteredController
  skip_before_filter :authenticate_user!, only: [:complete, :update_profile]

  include DeactivableHelper

  load_and_authorize_resource except: [:complete, :update_profile, :index]

  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :json, only: [:index]

  custom_actions :collection => [:complete]

  def dashboard
  end

  def select_company
    session[:current_company_id] = current_user.companies.find(params[:company_id]).id
    redirect_to root_path
  end

  def autocomplete
    buckets = []

    # Search users
    search = Sunspot.search(User) do
      keywords(params[:q]) do
        fields(:name)
        fields(:email)
      end
      any_of do
        with :active_company_ids, current_company.id # For the users
        with :inactive_company_ids, current_company.id # For the users
      end
    end
    buckets.push(label: "Users", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search teams
    search = Sunspot.search(Team) do
      keywords(params[:q]) do
        fields(:name)
      end
      with :company_id, current_company.id  # For the teams
    end
    buckets.push(label: "Teams", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search roles
    search = Sunspot.search(Role) do
      keywords(params[:q]) do
        fields(:name)
      end
      with :company_id, current_company.id  # For the teams
    end
    buckets.push(label: "Roles", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search campaigns
    search = Sunspot.search(Campaign) do
      keywords(params[:q]) do
        fields(:name)
      end
      with(:company_id, current_company.id)
    end
    buckets.push(label: "Campaigns", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search places
    search = Sunspot.search(Place, Area) do
      keywords(params[:q]) do
        fields(:name)
      end
    end
    buckets.push(label: "Places", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    render :json => buckets.flatten
  end

  protected
    def begin_of_association_chain
      current_company
    end

    def roles
      @roles ||= current_company.roles
    end

    def collection_to_json
      collection.map{|user| {
        :id => user.id,
        :last_name => user.last_name,
        :first_name => user.first_name,
        :full_name => user.full_name,
        :city => user.city,
        :state => user.state_name,
        :country => user.country_name,
        :email => user.email,
        :role => user.role_name,
        :last_activity_at => user.last_activity_at.try(:to_s,:full_friendly),
        :status => user.active_status(current_company.id),
        :active => user.active?,
        :links => {
            edit: edit_user_path(user),
            show: user_path(user),
            activate: activate_user_path(user),
            deactivate: deactivate_user_path(user),
            delete: delete_member_path(user)
        }
      }}
    end

    def delete_member_path(user)
      path = nil
      path = delete_member_team_path(params[:team], member_id: user.id) if params.has_key?(:team) && params[:team]
      path = delete_member_campaign_path(params[:campaign], member_id: user.id) if params.has_key?(:campaign) && params[:campaign]
      path
    end

    def sort_options
      {
        'last_name' => { :order => 'users.last_name' },
        'first_name' => { :order => 'users.first_name' },
        'city' => { :order => 'users.city' },
        'state' => { :order => 'users.state' },
        'country' => { :order => 'users.country' },
        'email' => { :order => 'users.email' },
        'role' => { :order => 'roles.name', :joins => {:company_users => :role}, :conditions => {:company_users => {:company_id => current_company } } },
        'last_activity' => { :order => 'users.last_activity_at' },
        'status' => { :order => 'company_users.active', :joins => :company_users, :conditions => {:company_users => {:company_id => current_company } } }
      }
    end
end
