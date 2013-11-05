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
  def index
    collection
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