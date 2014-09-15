class Results::PhotosController < FilteredController
  belongs_to :event, optional: true

  include DeactivableHelper
  include PhotosHelper

  defaults :resource_class => AttachedAsset

  helper_method :describe_filters, :return_path

  skip_load_and_authorize_resource

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Venue]
    })
    render :json => buckets.flatten
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
      format.json { render json:  {status: download.aasm_state, url: url} }
    end
  end

  protected

    def facets
      @facets ||= Array.new.tap do |f|
        f.push build_campaign_bucket
        f.push build_brands_bucket
        f.push build_areas_bucket
        f.push build_status_bucket
      end
    end

    def build_status_bucket
      {label: 'Active State', items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) }}
    end

    def search_params
      @search_params ||= begin
        super
        @search_params[:asset_type] = 'photo'
        @search_params
      end
    end

    def authorize_actions
      authorize! :index_photo_results, resource_class
    end

    def return_path
      results_reports_path
    end
end