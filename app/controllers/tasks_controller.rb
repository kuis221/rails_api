class TasksController < FilteredController
  belongs_to :event, :user, :optional => true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update, :show]

  has_scope :by_users

  load_and_authorize_resource :event
  load_and_authorize_resource through: :event

  helper_method :assignable_users

  def autocomplete
    buckets = []

    # Search compaigns
    search = Sunspot.search(Campaign) do
      keywords(params[:q]) do
        fields(:name)
      end
      with(:company_id, current_company.id)
      with(:aasm_state, ['active'])
    end
    buckets.push(label: "Campaigns", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

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
    def collection_to_json
      collection.map{|task| {
        :id => task.id,
        :title => task.title,
        :last_activity => task.updated_at.try(:to_s,:slashes),
        :due_at => task.due_at.try(:to_s, :slashes),
        :user => {
          :id => task.user.try(:id),
          :first_name => task.user.try(:first_name),
          :last_name => task.user.try(:last_name),
          :email => task.user.try(:email),
          :full_name => task.user.try(:full_name)
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
        current_user
      else
        super
      end
    end

    def search_params
      super
      @search_params[:user_id] = current_user.id if params[:scope] == 'user'
      @search_params[:user_id] = TeamsUser.select('user_id').where(team_id: current_user.teams.scoped_by_company_id(current_company)).map(&:user_id).uniq if params[:scope] == 'teams'
      @search_params
    end
end
