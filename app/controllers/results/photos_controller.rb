class Results::PhotosController < FilteredController
  belongs_to :event, optional: true

  include DeactivableHelper
  include PhotosHelper

  defaults :resource_class => AttachedAsset

  helper_method :describe_filters

  skip_load_and_authorize_resource

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Place]
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
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Campaigns", items: facet_search.facet(:campaign).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :campaign, count: x.count}) })
        f.push build_brands_bucket(facet_search.facet(:campaign).rows)
        f.push build_locations_bucket(facet_search)
        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
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
end