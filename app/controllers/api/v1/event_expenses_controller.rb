class Api::V1::EventExpensesController < Api::V1::ApiController
  inherit_resources

  belongs_to :event

  authorize_resource only: [:show, :create, :update, :destroy]

  resource_description do
    short 'Expenses'
    formats %w(json xml)
    error 400, 'Bad Request. he server cannot or will not process the request due to something that is perceived to be a client error.'
    error 404, 'Missing'
    error 401, 'Unauthorized access'
    error 500, 'Server crashed for some reason'
    description <<-EOS

    EOS
  end

  def_param_group :event_expense do
    param :event_expense, Hash, required: true, action_aware: true do
      param :category, String, required: true,
                               desc: 'Event expense category, should be one of '\
                                     'the category allowed categories, see '\
                                     '/api/v1/campaigns/:id/expense_catetories'
      param :expense_date, %r{\A\d{1,2}/\d{1,2}/\d{4}\z}, required: true, desc: 'Event date. Must be in format MM/DD/YYYY.'
      param :amount, String, required: true, desc: 'Event expense amount. Must be a number greater than 0'
      param :brand_id, String, required: false, desc: 'A valid brand id'
      param :reimbursable, %w(true false), required: false, desc: 'Reimbursable attribute'
      param :billable, %w(true false), required: false, desc: 'Billable attribute'
      param :merchant, String, required: false, desc: 'Merchant attribute'
      param :description, String, required: false, desc: 'Event expense description'
      param :receipt_attributes, Hash do
        param :direct_upload_url, String, desc: "The receipt URL. This should be a valid Amazon S3's URL."
        param :_destroy, ['1'], desc: 'Indicates that the receipt should be removed from the expense'
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
  def index
    authorize!(:expenses, parent)
    @expenses = parent.event_expenses.sort_by(&:id)
  end

  api :POST, '/api/v1/events/:event_id/event_expenses', 'Create a new event expense'
  param :event_id, :number, required: true, desc: 'Event ID'
  param_group :event_expense
  see 'campaigns#expense_categories'
  description <<-EOS
  Allows to attach an expense file to the event. The expense file should first be uploaded to Amazon S3 using the
  method described in this article[http://aws.amazon.com/articles/1434]. Once uploaded to S3, the resulting
  URL should be submitted to this method and the expense file will be attached to the event. Because the expense file is
  generated asynchronously, the thumbnails are not inmediately available.

  The format of the URL should be in the form: *https*://s3.amazonaws.com/<bucket_name>/uploads/<folder>/filename where:

  * *bucket_name*: brandscopic-stage
  * *folder*: the folder name where the photo was uploaded to
  EOS
  def create
    create! do |success, failure|
      success.json { render :show }
      failure.json { render json: resource.errors }
    end
  end

  api :PUT, '/api/v1/events/:event_id/event_expenses/:id', 'Update a expense'
  param :event_id, :number, required: true, desc: 'Event ID'
  param_group :event_expense
  see 'campaigns#expense_categories'
  description <<-EOS
  Allows to attach an expense file to the event. The expense file should first be uploaded to Amazon S3 using the
  method described in this article[http://aws.amazon.com/articles/1434]. Once uploaded to S3, the resulting
  URL should be submitted to this method and the expense file will be attached to the event. Because the expense file is
  generated asynchronously, the thumbnails are not inmediately available.

  The format of the URL should be in the form: *https*://s3.amazonaws.com/<bucket_name>/uploads/<folder>/filename where:

  * *bucket_name*: brandscopic-stage
  * *folder*: the folder name where the photo was uploaded to
  EOS
  def update
    update! do |success, failure|
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
  def form
    authorize!(:create_expense, parent)
    if parent.campaign.enabled_modules.include?('expenses') && can?(:expenses, parent) && can?(:create_expense, parent)
      bucket = AWS::S3.new.buckets[ENV['S3_BUCKET_NAME']]
      form = bucket.presigned_post(acl: 'public-read', success_action_status: 201)
                   .where(:key).starts_with('uploads/')
                   .where(:content_type).starts_with('')
      data = { fields: form.fields, url: "https://s3.amazonaws.com/#{ENV['S3_BUCKET_NAME']}/"  }
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

  api :DELETE, '/api/v1/events/:event_id/event_expenses/:id', 'Deletes an expense'
  param :event_id, :number, required: true, desc: 'Event ID'
  param :id, :number, required: true, desc: 'Expense ID'
  def destroy
    authorize!(:deactivate_expense, parent)
    destroy! do |success, failure|
      success.json { render json: { success: true, info: 'The expense was successfully deleted', data: {} } }
      success.xml  { render xml: { success: true, info: 'The expense was successfully deleted', data: {} } }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  protected

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(event_expense: [
      :amount, :category, :amount, :brand_id, :expense_date, :reimbursable,
      :billable, :merchant, :description, { receipt_attributes: [:direct_upload_url, :id, :_destroy] }])[:event_expense].tap do |p|
      p[:receipt_attributes][:id] = resource.receipt.id if p[:receipt_attributes].present? && p[:receipt_attributes][:_destroy].present?
    end
  end

  def skip_default_validation
    true
  end
end
