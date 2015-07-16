class Api::V1::CommentsController < Api::V1::ApiController
  inherit_resources

  belongs_to :event, :task, polymorphic: true

  authorize_resource only: [:show, :create, :update]

  resource_description do
    short 'Comments'
    formats %w(json xml)
    error 400, 'Bad Request. he server cannot or will not process the request due to something that is perceived to be a client error.'
    error 404, 'Record not found'
    error 401, 'Unauthorized access'
    error 500, 'Server crashed for some reason'
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/events/:event_id/comments', 'Get a list of comments for an Event'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :task_id, :number, required: false, desc: 'Event ID'
  description <<-EOS
    Returns a list of comments associated to the event.

    The results are sorted ascending by +id+.

    Each item have the following attributes:
    * *id*: the comment id
    * *content*: the comment text
    * *user*: the commenter's info (Only for task comments)
    * *created_at*: the date and time of creation for the comment
  EOS
  def index
    authorize!(:comments, parent)
    render json: parent.comments.order(:id)
  end

  api :POST, '/api/v1/events/:event_id/comments', 'Create a new comment for an event'
  api :POST, '/api/v1/tasks/:task_id/comments', 'Create a new comment for a task'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :task_id, :number, required: false, desc: 'Task ID'
  param :comment, Hash, required: true, action_aware: true do
    param :content, String, required: true, desc: 'Comment text'
  end
  description <<-EOS
  Allows to create a comment for an existing event.
  EOS

  def create
    create! do |success, failure|
      success.json { render json: resource }
      failure.json { render json: resource.errors }
    end
  end

  api :PUT, '/api/v1/events/:event_id/comments/:id', 'Updates a event comment'
  api :PUT, '/api/v1/tasks/:task_id/comments/:id', 'Updates a task comment'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :task_id, :number, required: false, desc: 'Task ID'
  param :id, :number, required: true, desc: 'Comment ID'
  param :comment, Hash, required: true, action_aware: true do
    param :content, String, required: true, desc: 'Comment text'
  end
  def update
    update! do |success, failure|
      success.json { render :show }
      success.xml  { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :DELETE, '/api/v1/events/:event_id/comments/:id', 'Deletes a event comment'
  api :DELETE, '/api/v1/tasks/:task_id/comments/:id', 'Deletes a task comment'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :task_id, :number, required: false, desc: 'Task ID'
  param :id, :number, required: true, desc: 'Comment ID'
  def destroy
    authorize!(:deactivate_comment, parent)
    destroy! do |success, failure|
      success.json { render json: { success: true, info: 'The comment was successfully deleted', data: {} } }
      success.xml  { render xml: { success: true, info: 'The comment was successfully deleted', data: {} } }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  protected

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(comment: [:content])[:comment]
  end

  def skip_default_validation
    true
  end
end
