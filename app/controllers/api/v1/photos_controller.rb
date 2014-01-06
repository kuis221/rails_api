class Api::V1::PhotosController < Api::V1::FilteredController

  belongs_to :event, optional: true

  defaults :resource_class => AttachedAsset

  resource_description do
    short 'Photos'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true
    param :company_id, :number, required: true
    description <<-EOS

    EOS
  end

  api :GET, '/api/v1/events/:event_id/photos', "Get a list of photos for an Event"
  param :event_id, :number, required: true, desc: "Event ID"
  param :brand, Array, :desc => "A list of brand ids to filter the results"
  param :place, Array, :desc => "A list of places to filter the results"
  param :status, Array, :desc => "A list of photo status to filter the results. Options: Active, Inactive"
  param :page, :number, :desc => "The number of the page, Default: 1"
  example <<-EOS
  GET /api/v1/events/1223/photos
  {
      "page": 1,
      "total": 5,
      "results": [
          {
              "id": 45554,
              "file_file_name": "SV-T101-P005-111413.JPG",
              "file_content_type": "image/jpeg",
              "file_file_size": 611320,
              "created_at": "2013-11-19T00:49:24-08:00",
              "active": true,
              "file_small": "http://s3.amazonaws.com/brandscopic-stage/attached_assets/files/000/045/554/small/SV-T101-P005-111413.JPG?1384851148",
              "file_medium": "http://s3.amazonaws.com/brandscopic-stage/attached_assets/files/000/045/554/medium/SV-T101-P005-111413.JPG?1384851148",
              "file_original": "http://s3.amazonaws.com/brandscopic-stage/attached_assets/files/000/045/554/original/SV-T101-P005-111413.JPG?1384851148"
          },
          {
              "id": 45553,
              "file_file_name": "SV-T101-P001-111413.JPG",
              "file_content_type": "image/jpeg",
              "file_file_size": 651591,
              "created_at": "2013-11-19T00:49:16-08:00",
              "active": true,
              "file_small": "http://s3.amazonaws.com/brandscopic-stage/attached_assets/files/000/045/553/small/SV-T101-P001-111413.JPG?1384851145",
              "file_medium": "http://s3.amazonaws.com/brandscopic-stage/attached_assets/files/000/045/553/medium/SV-T101-P001-111413.JPG?1384851145",
              "file_original": "http://s3.amazonaws.com/brandscopic-stage/attached_assets/files/000/045/553/original/SV-T101-P001-111413.JPG?1384851145"
          }
          ...
      ]
  }
  EOS
  def index
    collection
  end

  api :POST, '/api/v1/events/:event_id/photos', "Adds a new photo to a event"
  param :event_id, :number, required: true, desc: "Event ID"
  param :attached_asset, Hash, required: true do
    param :direct_upload_url, String, desc: "The photo URL. This should be a valid Amazon S3's URL."
  end
  description <<-EOS
  Allows to attach a new photo to the event. The photo should first be uploaded to Amazon S3 using the
  method described in this article[http://aws.amazon.com/articles/1434]. Once uploaded to S3, the resulting
  URL should be submitted to this method and the photo will be attached to the event. Because the photo is
  generated asynchronously, the thumbnails are not inmediately available.
  EOS
  example <<-EOS
  POST /api/v1/events/192/photos.json?auth_token=AJHshslaA.sdd&company_id=1
  DATA:
  {
    attached_asset: {
      direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/SV-T101-P005-111413.jpg'
    }
  }

  RESPONSE:
  {
      "id": 45554,
      "file_file_name": "SV-T101-P005-111413.JPG",
      "file_content_type": "image/jpeg",
      "file_file_size": 611320,
      "created_at": "2013-11-19T00:49:24-08:00",
      "active": true
  }
  EOS
  def create
    create! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  protected

    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(attached_asset: [:direct_upload_url])[:attached_asset]
    end

    def search_params
      @search_params ||= begin
        super
        @search_params.merge({event_id: parent.id, asset_type: 'photo'})
      end
    end

    def permitted_search_params
      params.permit({brand: [], place: [], status: []})
    end
end