class Api::V1::EventExpensesController < Api::V1::ApiController

  inherit_resources

  belongs_to :event

  resource_description do
    short 'Expenses'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/events/:event_id/event_expenses', "Get a list of expenses for an Event"
  param :event_id, :number, required: true, desc: "Event ID"
  description <<-EOS
    Returns a list of expenses associated to the event.

    The results are sorted ascending by +id+.

    Each item have the following attributes:
    * *id*: the expense id
    * *name*: the expense name/label
    * *amount*: the expense amount
    * *receipt:* attachet asset for the expense invoice
      This will contain the following attributes:
      * *id:* the ID of the attached asset
      * *file_file_name:* the name/label of the attached asset
      * *file_content_type:* the attached asset type
      * *file_file_size:* the attached asset size
      * *created_at:* creation date for the attached asset
      * *active:* status (true/false) of the attached asset
      * *file_small:* URL for the small size representation of the attached asset
      * *file_medium:* URL for the medium size representation of the attached asset
      * *file_original:* URL for the original size representation of the attached asset
  EOS
  example <<-EOS
    An example with expenses for an event in the response
    GET: /api/v1/events/1351/event_expenses.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
      {
        "id": 28,
        "name": "Expense #1",
        "amount": "200.0",
        "receipt": {
          "id": 26,
          "file_file_name": "image1.jpg",
          "file_content_type": "image/jpeg",
          "file_file_size": 44705,
          "created_at": "2013-10-22T13:30:12-07:00",
          "active": true,
          "file_small": "http://s3.amazonaws.com/brandscopic/attached_assets/files/000/000/026/small/image1.jpg?1382473842",
          "file_medium": "http://s3.amazonaws.com/brandscopic/attached_assets/files/000/000/026/medium/image1.jpg?1382473842",
          "file_original": "http://s3.amazonaws.com/brandscopic/attached_assets/files/000/000/026/original/image1.jpg?1382473842"
        }
      },
      {
        "id": 29,
        "name": "Expense #2",
        "amount": "359.0",
        "receipt": {
          "id": 27,
          "file_file_name": "image2.jpg",
          "file_content_type": "image/jpeg",
          "file_file_size": 10461,
          "created_at": "2013-10-22T14:25:13-07:00",
          "active": true,
          "file_small": "http://s3.amazonaws.com/brandscopic/attached_assets/files/000/000/027/small/image2.jpg?1382477120",
          "file_medium": "http://s3.amazonaws.com/brandscopic/attached_assets/files/000/000/027/medium/image2.jpg?1382477120",
          "file_original": "http://s3.amazonaws.com/brandscopic/attached_assets/files/000/000/027/original/image2.jpg?1382477120"
        }
      }
    ]
  EOS
  def index
    @expenses = parent.event_expenses.sort_by {|e| e.id}
  end

  api :POST, '/api/v1/events/:event_id/event_expenses', 'Create a new event expense'
  param :event_id, :number, required: true, desc: "Event ID"
  param :name, String, required: true, desc: "Event expense name/label"
  param :amount, String, required: true, desc: "Event expense amount"
  def create
    create! do |success, failure|
      success.json { render :show }
      failure.json { render json: resource.errors }
    end
  end

  protected

    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      p = params.dup
      p[:event_expense] ||= {}
      p[:event_expense][:name] = params[:name]
      p[:event_expense][:amount] = params[:amount]

      p = p.permit(event_expense: [:amount, {receipt_attributes:[:direct_upload_url]}, :name])[:event_expense]
    end
end