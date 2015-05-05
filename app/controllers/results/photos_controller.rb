class Results::PhotosController < FilteredController
  belongs_to :event, optional: true

  include DeactivableController
  include PhotosHelper

  defaults resource_class: AttachedAsset

  helper_method :return_path

  skip_load_and_authorize_resource

  def download
    @download = AssetDownload.find_by_uid(params[:download_id])
  end

  def new_download
    @download = AttachedAsset.compress(params[:photos])
  end

  def download_status
    url = nil
    download = AssetDownload.find_by_uid(params[:download_id])
    url = download.download_url if download.completed?
    respond_to do |format|
      format.json { render json:  { status: download.aasm_state, url: url } }
    end
  end

  protected

  def search_params
    @search_params || (super.tap do |p|
      p[:search_permission] = :index_results
      p[:search_permission_class] = EventData
      p[:asset_type] = 'photo'
    end)
  end

  def authorize_actions
    authorize! :index_photo_results, resource_class
  end

  def return_path
    results_reports_path
  end

  def permitted_search_params
    Event.searchable_params.concat([tag: [], rating: []])
  end
end
