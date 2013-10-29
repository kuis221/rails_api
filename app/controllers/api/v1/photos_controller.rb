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

  api :GET, '/api/v1/events/:event_id/photos'
  param :event_id, :number, required: true, desc: "Event ID"
  def index
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
        @search_params.merge({event_id: parent.id})
      end
    end

end