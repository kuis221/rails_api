class PhotosController < FilteredController
  respond_to :js, only: :create

  belongs_to :event, optional: true

  include DeactivableHelper

  defaults :resource_class => AttachedAsset

  skip_load_and_authorize_resource

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Place]
    })
    render :json => buckets.flatten
  end

  protected

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Campaigns", items: facet_search.facet(:campaign).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :campaign, count: x.count}) })
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
end