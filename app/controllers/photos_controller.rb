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
        f.push build_brands_bucket(facet_search.facet(:campaign).rows)
        f.push build_locations_bucket(facet_search.facet(:place).rows)
        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
    end

    def build_brands_bucket(campaings)
      campaigns_counts = Hash[campaings.map{|x| id, name = x.value.split('||'); [id.to_i, x.count] }]
      brands = {}
      Campaign.includes(:brands).where(id: campaigns_counts.keys).each do |campaign|
        campaing_brands = Hash[campaign.brands.map{|b| [b.id, {label: b.name, id: b.id, name: :brand, count: campaigns_counts[campaign.id]}] }]
        brands.merge!(campaing_brands){|k,a1,a2|  a1.merge({count: (a1[:count] + a2[:count])}) }
      end
      brands = brands.values.sort{|a, b| b[:count] <=> a[:count] }
      {label: 'Brands', items: brands}
    end

    def build_locations_bucket(facets)
      first_five = facets.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :place}) }.first(5)
      first_five_ids = first_five.map{|x| x[:id] }
      locations = {}
      locations = Place.where(id: facets.map{|x| x.value.split('||')[0]}.uniq.reject{|id| first_five_ids.include?(id) }).load_organized(current_company.id)

      {label: 'Locations', top_items: first_five, items: locations}
    end

    def search_params
      @search_params ||= begin
        super
        @search_params[:asset_type] = 'photo'
        @search_params
      end
    end
end