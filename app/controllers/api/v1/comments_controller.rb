class Api::V1::CommentsController < Api::V1::ApiController

  inherit_resources

  belongs_to :event

  resource_description do
    short 'Comments'
    formats ['json', 'xml']
    error 404, "Missing"
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
        "name": "Comment text #1"
        "created_at": "2014-01-07T12:52:22-08:00"
      },
      {
        "id": 19,
        "name": "Comment text #2"
        "created_at": "2014-01-07T12:54:35-08:00"
      }
    ]
  EOS
  def index
    @comments = parent.comments.sort_by {|c| c.id}
  end
end