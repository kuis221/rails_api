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
    * *name*: the expense name
    * *amount*: the expense amount
  EOS
  example <<-EOS
    An example with expenses for an event in the response
    GET: /api/v1/events/1351/event_expenses.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
      {
          "id": 28,
          "name": "Expense #1",
          "amount": "200.0"
      },{
          "id": 29,
          "name": "Expense #2",
          "amount": "359.0"
      }
    ]
  EOS
  def index
    @expenses = parent.event_expenses.sort_by {|e| e.id}
  end

end