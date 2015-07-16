class Api::V1::TasksController < Api::V1::FilteredController
  belongs_to :event, optional: true

  resource_description do
    short 'Tasks'
    formats %w(json xml)
    error 400, 'Bad Request. he server cannot or will not process the request due to something that is perceived to be a client error.'
    error 404, 'Missing'
    error 401, 'Unauthorized access'
    error 500, 'Server crashed for some reason'
    description <<-EOS

    EOS
  end

  def_param_group :task do
    param :task, Hash, required: true, action_aware: true do
      param :title, String, required: true, desc: 'Task Title'
      param :due_at, %r{\A\d{1,2}/\d{1,2}/\d{4}\z}, required: false, desc: "Task's due date. Should be in format MM/DD/YYYY."
      param :completed, [true, false], required: false, desc: "Task's completeness state. By default it's false."
      param :active, [true, false, 'true', 'false'], required: false, desc: "Task's active state'. Default: true"
      param :company_user_id, :number, desc: 'Company User ID. Required when the task is not being assigned to a event'
    end
  end

  api :GET, '/api/v1/events/:event_id/tasks', 'Get a list of taks for an Event'
  api :GET, '/api/v1/tasks/team', "Get a list of taks for the user's teams"
  api :GET, '/api/v1/tasks/mine', 'Get a list of taks for the user'
  param :event_id, :number, required: false, desc: 'Event ID, required when getting the list of tasks for a event'
  param :status, Array, desc: 'A list of photo status to filter the results. Options: Active, Inactive'
  param :task_status, Array, desc: 'A list of photo status to filter the results. Options: Late, Complete, Incomplete, Assigned, Unassigned'
  param :page, :number, desc: 'The number of the page, Default: 1'
  def index
    authorize_index!
    render json: paginated_result
  end

  api :POST, '/api/v1/tasks', 'Create a new task'
  api :POST, '/api/v1/events/:event_id/tasks', 'Create a new task for an Event'
  param :event_id, :number, required: false, desc: 'Event ID'
  param_group :task
  def create
    authorize! :create, build_resource
    create! do |success, failure|
      success.json { render json: resource }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
    end
  end

  api :PUT, '/api/v1/tasks/:id', 'Update a task\'s details'
  param :id, :number, required: true, desc: 'Task ID'
  param :event_id, :number, required: false, desc: 'Event ID'
  param_group :task
  def update
    authorize! :create, resource
    update! do |success, failure|
      success.json { render json: resource }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
    end
  end


  api :GET, '/api/v1/tasks/:id', 'Get a task\'s details'
  param :id, :number, required: true, desc: 'Task ID'
  def show
    authorize! :show, resource
    render json: resource
  end

  protected

  def permitted_params
    params.require(:task).permit(:title, :due_at, :company_user_id, :active, :completed)
  end

  def permitted_search_params
    params.permit(:event_id, { status: [] }, task_status: [])
  end

  def search_params
    super
    @search_params.merge!(Task.search_params_for_scope(params[:scope], current_company_user))
  end

  def authorize_index!
    if params[:scope] == 'user'
      authorize!(:index_my, Task)
    elsif params[:scope] == 'teams'
      authorize!(:index_team, Task)
    else
      authorize!(:index, Task)
    end
  end

  # we are handling custom validations in methods
  def skip_default_validation
    true
  end
end
