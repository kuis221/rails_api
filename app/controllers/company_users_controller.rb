class CompanyUsersController < FilteredController
  include DeactivableHelper


  before_filter :load_users_for_event, only: :event
  load_and_authorize_resource except: [:index]

  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :json, only: [:index]

  helper_method :assignable_campaigns

  custom_actions :collection => [:complete]

  def autocomplete
    buckets = []

    # Search users
    search = Sunspot.search(CompanyUser) do
      keywords(params[:q]) do
        fields(:name)
        fields(:email)
      end
      with :company_id, current_company.id # For the users
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

  def event
    render :index
  end

  def select_company
    begin
      company = current_user.company_users.find_by_company_id_and_active(params[:company_id], true) or raise ActiveRecord::RecordNotFound
      session[:current_company_id] = company.company_id
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "You are not allowed login into this company"
    end
    redirect_to root_path
  end

  def assignable_campaigns
    current_company.campaigns.active.order('campaigns.name asc')
  end

  def update
    update! do |success, failure|
      success.js {
        if resource.user.id == current_user.id
          sign_in resource.user, :bypass => true
        end
      }
    end
  end

  protected

    def roles
      @roles ||= current_company.roles
    end

    def as_role
      { as: :admin }
    end

    def role_given?
      current_user.id != resource.user_id
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)
        f.push(label: "Roles", items: facet_search.facet(:role).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :role}) } )
        f.push(label: "Teams", items: facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :team}) })
        f.push(label: "Campaigns", items: facet_search.facet(:campaigns).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :campaign}) })
        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
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
        :status => user.active_status,
        :active => user.active?,
        :links => {
            edit: edit_company_user_path(user),
            show: company_user_path(user),
            activate: activate_company_user_path(user),
            deactivate: deactivate_company_user_path(user),
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

    def load_users_for_event
      event = current_company.events.find(params[:event_id])
      # INNER JOIN "memberships" ON "memberships"."company_user_id" = "company_users"."id" AND "memberships"."memberable_type" = 'Event' INNER JOIN "events" ON "events"."id" = "memberships"."memberable_id"
      teams = CompanyUser.scoped_by_company_id(current_company).active.joins(:teams).where(active: true, teams: {id: event.team_ids})
      users = CompanyUser.scoped_by_company_id(current_company).active.joins(:events).where(active: true, events: {id: event.id})
      @users = CompanyUser.from("(#{teams.to_sql} UNION #{users.to_sql}) AS company_users ")
      @collection_count_scope = @users
      set_collection_ivar @users
    end

end
