class BrandPortfoliosController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update, :brands, :delete_brand]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions member: [:select_brands, :add_brands]

  def autocomplete
    buckets = autocomplete_buckets({
      brands: [Brand, BrandPortfolio]
    })
    render :json => buckets.flatten
  end

  def select_brands
  end

  def add_brands
    @brand = Brand.find(params[:brand_id])
    unless resource.brand_ids.include?(@brand.id)
      resource.brands << @brand
      resource.solr_index
    end
  end

  def delete_brand
    @brand = Brand.find(params[:brand_id])
    resource.brands.delete(@brand)
    resource.solr_index
  end

  private
    def permitted_params
      params.permit(brand_portfolio: [:name, :description, :campaigns_ids])[:brand_portfolio]
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push build_brand_bucket facet_search
        f.push(label: "Active State", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end
    
    def build_brand_bucket facet_search
      items = facet_search.facet(:brands).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :brand}) } 
      items = items.sort{|a, b| a[:label] <=> b[:label] }
      {label: "Brands", items: items }
    end
end
