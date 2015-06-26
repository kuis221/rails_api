class Api::V1::PhotosController < Api::V1::FilteredController
  include SunspotIndexing

  belongs_to :event, optional: true

  defaults resource_class: AttachedAsset

  after_action :force_resource_reindex, only: [:create, :update]

  authorize_resource class: AttachedAsset, only: [:show, :destroy]

  resource_description do
    short 'Photos'
    formats %w(json xml)
    error 400, 'Bad Request. The server cannot or will not process the request due to something that is perceived to be a client error.'
    error 404, 'Missing'
    error 401, 'Unauthorized access'
    error 500, 'Server crashed for some reason'
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/events/:event_id/photos', 'Get a list of photos for an Event'
  param :event_id, :number, required: true, desc: 'Event ID'
  param :brand, Array, desc: 'A list of brand ids to filter the results'
  param :place, Array, desc: 'A list of places to filter the results'
  param :status, Array, desc: 'A list of photo status to filter the results. Options: Active, Inactive'
  param :page, :number, desc: 'The number of the page, Default: 1'

  def index
    authorize!(:photos, parent)
    render json: paginated_result
  end

  api :POST, '/api/v1/events/:event_id/photos', 'Adds a new photo to a event'
  param :event_id, :number, required: true, desc: 'Event ID'
  param :attached_asset, Hash, required: true do
    param :direct_upload_url, String, desc: "The photo URL. This should be a valid Amazon S3's URL."
  end
  description <<-EOS
  Allows to attach a new photo to the event. The photo should first be uploaded to Amazon S3 using the
  method described in this article[http://aws.amazon.com/articles/1434]. Once uploaded to S3, the resulting
  URL should be submitted to this method and the photo will be attached to the event. Because the photo is
  generated asynchronously, the thumbnails are not inmediately available.

  The format of the URL should be in the form: *https*://s3.amazonaws.com/<bucket_name>/uploads/<folder>/filename where:

  * *bucket_name*: brandscopic-stage
  * *folder*: the folder name where the photo was uploaded to
  EOS
  def create
    authorize!(:create_photo, parent)
    create! do |success, failure|
      success.json { render json: resource }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
    end
  end

  api :PUT, '/api/v1/events/:event_id/photos/:id', 'Updates a photo'
  param :event_id, :number, required: true, desc: 'Event ID'
  param :id, :number, required: true, desc: 'Photo ID'
  param :attached_asset, Hash, required: true, action_aware: true do
    param :active, %w(true false), required: true, desc: 'Photo status'
  end
  def update
    authorize! :deactivate_photo, Event
    update! do |success, failure|
      success.json { render :show }
      success.xml  { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :GET, '/api/v1/events/:event_id/photos/form', 'Returns a list of requred fields for making a POST to S3'
  description <<-EOS
  This method returns all the info required to make a POST to Amazon S3 to upload a new file. The key sent to S3 should start with
  /uploads and has to be created into a new folder with a unique generated name. Ideally using a GUID. Eg:
  /uploads/9afa6775-2c8e-44f8-9cda-280e80446ced/My file.jpg

  The signature will expire 1 hour after it's generated, therefore, it's recommended to not cache these fields for long time.
  EOS
  def form
    authorize!(:create_photo, parent)
    if parent.campaign.enabled_modules.include?('photos') && can?(:photos, parent) && can?(:create_photo, parent)
      bucket = AWS::S3.new.buckets[ENV['S3_BUCKET_NAME']]
      form = bucket.presigned_post(acl: 'public-read', success_action_status: 201)
                  .where(:key).starts_with('uploads/')
      # .where(:content_type).starts_with('image/')
      data = { fields: form.fields, url: "https://s3.amazonaws.com/#{ENV['S3_BUCKET_NAME']}/" }
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
    params.permit(attached_asset: [:direct_upload_url, :active])[:attached_asset]
  end

  def search_params
    @search_params ||= begin
      super
      @search_params.merge(event_id: parent.id, asset_type: 'photo')
    end
  end

  def permitted_search_params
    params.permit(brand: [], place: [], status: [])
  end

  def skip_default_validation
    true
  end
end
