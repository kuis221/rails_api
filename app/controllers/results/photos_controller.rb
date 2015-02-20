class Results::PhotosController < FilteredController
  belongs_to :event, optional: true

  include DeactivableHelper
  include PhotosHelper

  defaults resource_class: AttachedAsset

  helper_method :return_path

  skip_load_and_authorize_resource

  def autocomplete
    buckets = autocomplete_buckets(campaigns: [Campaign],
                                   brands: [Brand, BrandPortfolio],
                                   places: [Venue])
    render json: buckets.flatten
  end

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

  def facets
    @facets ||= Array.new.tap do |f|
      f.push build_campaign_bucket
      f.push build_brands_bucket
      f.push build_areas_bucket
      f.push build_tags_bucket
      f.push build_rating_bucket
      f.push build_status_bucket
      f.concat build_custom_filters_bucket
    end
  end

  def build_status_bucket
    { label: 'Status', items: %w(Active Inactive).map { |x| build_facet_item(label: x, id: x, name: :status, count: 1) } }
  end

  def build_tags_bucket
    tags = current_company.tags.order(:name).pluck(:name, :id).map do |t|
      build_facet_item(label: t[0], id: t[1], name: :tag)
    end
    { label: 'Tags', items: tags }
  end

  def build_rating_bucket
    ratings = [
      build_facet_item(label: '5', id: '5', name: :rating),
      build_facet_item(label: '4', id: '4', name: :rating),
      build_facet_item(label: '3', id: '3', name: :rating),
      build_facet_item(label: '2', id: '2', name: :rating),
      build_facet_item(label: '1', id: '1', name: :rating),
      build_facet_item(label: '0', id: '0', name: :rating)
    ]
    { label: 'Star Rating', items: ratings, type: 'rating' }
  end

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
    permitted_events_search_params.concat([tag: [], rating: []])
  end
end
