class TasksController < FilteredController
  belongs_to :event, :company_user, :optional => true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update, :show]

  has_scope :by_users

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  helper_method :assignable_users

  before_filter :set_body_class, only: :index

  def autocomplete
    buckets = []

    # Search tasks
    search = Sunspot.search(Task) do
      keywords(params[:q]) do
        fields(:title)
      end
      with(:company_id, current_company.id)
      with(:status, ['Active', 'Completed', 'Incompleted'])
    end
    buckets.push(label: "Tasks", value: search.results.first(5).map{|x| {label: x.title, value: x.id, type: x.class.name.downcase} })


    # Search compaigns
    search = Sunspot.search(Campaign) do
      keywords(params[:q]) do
        fields(:name)
      end
      with(:company_id, current_company.id)
      with(:aasm_state, ['active'])
    end
    buckets.push(label: "Campaigns", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })


    if params[:scope] == 'teams'
      # Search users
      search = Sunspot.search(CompanyUser, Team) do
        keywords(params[:q]) do
          fields(:name)
        end
        any_of do
          with :company_id, current_company.id  # For the teams
        end
      end
      buckets.push(label: "People", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })
    end

    render :json => buckets.flatten
  end

  def assignable_users
    users = []
    unless resource.event.nil?
      users =  company_users.active.by_events(resource.event)
      users += company_users.active.by_teams(resource.event.teams)
      users.uniq!
    end
    users.sort{|a,b| a.name <=> b.name}
  end

  private
    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :start_date, :end_date, :company_user_id, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Campaigns", items: facet_search.facet(:campaign).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :campaign, count: x.count}) })
        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
    end

    def collection_to_json
      collection.map{|task| {
        :id => task.id,
        :title => task.title,
        :last_activity => task.last_activity.try(:to_s,:slashes),
        :due_at => task.due_at.try(:to_s, :slashes),
        :user => {
          :id => task.company_user.try(:id),
          :first_name => task.company_user.try(:first_name),
          :last_name => task.company_user.try(:last_name),
          :email => task.company_user.try(:email),
          :full_name => task.company_user.try(:full_name)
        },
        :active => task.active?,
        :completed => task.completed,
        :complete_form => view_context.simple_form_for([task.event, task], remote: true) {|f| f.input :completed, :label => false, :input_html => {:class => 'task-completed-checkbox'}},
        :links => {
            edit: edit_resource_url(task),
            comments: task_comments_path(task),
            activate: url_for([:activate, parent, task]),
            deactivate: url_for([:deactivate, parent, task])
        }
      }}
    end

    def parent
      if params[:scope] == 'user'
        current_company_user
      else
        super
      end
    end

    def search_params
      super
      @search_params[:company_user_id] = current_company_user.id if params[:scope] == 'user'
      @search_params[:company_user_id] = CompanyUser.joins(:teams).where(teams: {id: current_company_user.teams.select('teams.id').active.map(&:id)}).map(&:id).uniq.reject{|id| id == current_company_user.id } if params[:scope] == 'teams'
      @search_params
    end

    def set_body_class
      @custom_body_class = params[:scope]
    end
end
