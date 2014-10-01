class Api::V1::EventExpensesController < Api::V1::ApiController
  inherit_resources

  belongs_to :event

  authorize_resource only: [:show, :create, :update, :destroy]

  resource_description do
    short 'Expenses'
    formats %w(json xml)
    error 404, 'Missing'
    error 401, 'Unauthorized access'
    error 500, 'Server crashed for some reason'
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
    description <<-EOS

    EOS
  end

  def_param_group :event_expense do
    param :event_expense, Hash, required: true, action_aware: true do
      param :name, String, required: true, desc: 'Event expense name/label'
      param :amount, String, required: true, desc: 'Event expense amount'
      param :receipt_attributes, Hash do
        param :direct_upload_url, String, desc: "The receipt URL. This should be a valid Amazon S3's URL."
      end
    end
  end

  api :GET, '/api/v1/events/:event_id/event_expenses', 'Get a list of expenses for an Event'
  param :event_id, :number, required: true, desc: 'Event ID'
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
    authorize!(:expenses, parent)
    @expenses = parent.event_expenses.sort_by(&:id)
  end

  api :POST, '/api/v1/events/:event_id/event_expenses', 'Create a new event expense'
  param :event_id, :number, required: true, desc: 'Event ID'
  param_group :event_expense
  description <<-EOS
  Allows to attach an expense file to the event. The expense file should first be uploaded to Amazon S3 using the
  method described in this article[http://aws.amazon.com/articles/1434]. Once uploaded to S3, the resulting
  URL should be submitted to this method and the expense file will be attached to the event. Because the expense file is
  generated asynchronously, the thumbnails are not inmediately available.

  The format of the URL should be in the form: *https*://s3.amazonaws.com/<bucket_name>/uploads/<folder>/filename where:

  * *bucket_name*: brandscopic-stage
  * *folder*: the folder name where the photo was uploaded to
  EOS
  example <<-EOS
  POST /api/v1/events/192/event_expenses.json?auth_token=AJHshslaA.sdd&company_id=1
  DATA:
  {
    event_expense: {
      name: 'Expense #1',
      amount: 350,
      receipt_attributes: {
        direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/12390bs-25632sj-2-83KjsH984sd/SV-T101-P005-111413.jpg'
      }
    }
  }

  RESPONSE:
  {
    "id": 196,
    "name": "Expense #1",
    "amount": "350.0",
    "receipt": {
      "id": 45554,
      "file_file_name": "SV-T101-P005-111413.JPG",
      "file_content_type": "image/jpeg",
      "file_file_size": 611320,
      "created_at": "2013-11-19T00:49:24-08:00",
      "active": true
      "file_small": "http://s3.amazonaws.com/brandscopic-dev/attached_assets/files/000/000/45554/small/SV-T101-P005-111413.jpg?1389026763",
      "file_medium": "http://s3.amazonaws.com/brandscopic-dev/attached_assets/files/000/000/45554/medium/SV-T101-P005-111413.jpg?1389026763",
      "file_original": "http://s3.amazonaws.com/brandscopic-dev/attached_assets/files/000/000/45554/original/SV-T101-P005-111413.jpg?1389026763"
    }
  }
  EOS
  def create
    create! do |success, failure|
      success.json { render :show }
      failure.json { render json: resource.errors }
    end
  end

  api :GET, '/api/v1/events/:event_id/event_expenses/form', 'Returns a list of requred fields for uploading a file to S3'
  description <<-EOS
  This method returns all the info required to make a POST to Amazon S3 to upload a new file. The key sent to S3 should start with
  /uploads and has to be created into a new folder with a unique generated name. Ideally using a GUID. Eg:
  /uploads/9afa6775-2c8e-44f8-9cda-280e80446ced/My file.jpg

  The signature will expire 1 hour after it's generated, therefore, it's recommended to not cache these fields for long time.
  EOS
  example <<-EOS
  GET /api/v1/events/123/event_expenses/form.json?company_id=1&auth_token=XXsikw982okds93
  {
      "fields": {
          "AWSAccessKeyId": "AKIAIJSENKEXXZNMLW3VQ",
          "key": null,
          "policy": "ioJleHBpcmF0S0zMVQyMTo0NToyNFoiLCJjb25kaXRpb25zIjsoOHYLSSdHMtd2l0aCIsIiRrZXkiLCJ1cGxvYWRzLyJdLHsiYnVja2V0IjoiYnJhbmRzY29waWMtZGV2In0sWyJzdGFydHMtd2l0aCIsIiRrZXkiLCIiXSx7IlNlY3VyZSI6InRydWTYosS",
          "signature": "Q8TG16PD850JapPweQGAaK/o4NE=",
          "Secure": "true"
      },
      "url": "https://bucket-name.s3.amazonaws.com/"
  }
  EOS
  def form
    authorize!(:create_expense, parent)
    if parent.campaign.enabled_modules.include?('expenses') && can?(:expenses, parent) && can?(:create_expense, parent)
      bucket = AWS::S3.new.buckets[ENV['S3_BUCKET_NAME']]
      form = bucket.presigned_post(acl: 'public-read', success_action_status: 201)
                  .where(:key).starts_with('uploads/')
                  .where(:content_type).starts_with('')
      data = { fields: form.fields, url: "https://#{ENV['S3_BUCKET_NAME']}.s3.amazonaws.com/"  }
      respond_to do |format|
        format.json { render json: data }
        format.xml { render xml: data }
      end
    else
      respond_to do |format|
        format.json {  render status: 401, json: {} }
        format.xml { render status: 401, xml: {} }
      end
    end
  end

  protected

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(event_expense: [:amount, { receipt_attributes: [:direct_upload_url] }, :name])[:event_expense]
  end

  def skip_default_validation
    true
  end
end
