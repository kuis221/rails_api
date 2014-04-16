class Api::V1::CommentsController < Api::V1::ApiController

  inherit_resources

  belongs_to :event

  resource_description do
    short 'Comments'
    formats ['json', 'xml']
    error 404, "Record not found"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/events/:event_id/comments', "Get a list of comments for an Event"
  param :event_id, :number, required: true, desc: "Event ID"
  description <<-EOS
    Returns a list of comments associated to the event.

    The results are sorted ascending by +id+.

    Each item have the following attributes:
    * *id*: the comment id
    * *name*: the comment text
    * *created_at*: the date and time of creation for the comment
  EOS
  example <<-EOS
    An example with comments for an event in the response
    GET: /api/v1/events/1351/comments.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
      {
        "id": 18,
        "content": "Comment text #1",
        "created_at": "2014-01-07T12:52:22-08:00"
      },
      {
        "id": 19,
        "content": "Comment text #2",
        "created_at": "2014-01-07T12:54:35-08:00"
      }
    ]
  EOS
  def index
    @comments = parent.comments.order(:id)
  end

  api :POST, '/api/v1/events/:event_id/comments', 'Create a new comment for an event'
  param :event_id, :number, required: true, desc: "Event ID"
  param :comment, Hash, required: true, :action_aware => true do
    param :content, String, required: true, desc: "Comment text"
  end
  description <<-EOS
  Allows to create a comment for an existing event.
  EOS
  example <<-EOS
  POST /api/v1/events/192/comments.json?auth_token=AJHshslaA.sdd&company_id=1
  DATA:
  {
    comment: {
      content: 'Text for the first comment'
    }
  }

  RESPONSE:
  {
    {
      "id": 20,
      "content": "Text for the first comment"
      "created_by_id": 1,
      "created_at": "2014-01-07T10:16:39-08:00"
    }
  }
  EOS

  def create
    create! do |success, failure|
      success.json { render :show }
      failure.json { render json: resource.errors }
    end
  end

  api :PUT, '/api/v1/events/:event_id/comments/:id', 'Update a comment'
  param :event_id, :number, required: true, desc: "Event ID"
  param :id, :number, required: true, desc: "Comment ID"
  param :comment, Hash, required: true, :action_aware => true do
    param :content, String, required: true, desc: "Comment text"
  end
  example <<-EOS
  POST /api/v1/events/192/comments/12.json?auth_token=AJHshslaA.sdd&company_id=1
  DATA:
  {
    comment: {
      content: 'This is the new content for the comment'
    }
  }

  RESPONSE:
  {
    {
      "id": 20,
      "content": "This is the new content for the comment"
      "created_at": "2014-01-07T10:16:39-08:00"
    }
  }
  EOS
  def update
    update! do |success, failure|
      success.json { render :show }
      success.xml  { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :DELETE, '/api/v1/events/:event_id/comments/:id', 'Deletes a comment'
  param :event_id, :number, required: true, desc: "Event ID"
  param :id, :number, required: true, desc: "Comment ID"
  example <<-EOS
  DELETE /api/v1/events/192/comments/12.json?auth_token=AJHshslaA.sdd&company_id=1
  RESPONSE:
  {
    success: true
    info: "The comment was successfully deleted"
    data: { }
  }
  EOS
  def destroy
    destroy! do |success, failure|
      success.json { render json: {success: true, info: 'The comment was successfully deleted', data: {} } }
      success.xml  { render xml: {success: true, info: 'The comment was successfully deleted', data: {} } }
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
end