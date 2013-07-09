class BrandPortfoliosController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions member: [:select_brands, :add_brands]

  load_and_authorize_resource except: :index

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
    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Brands", items: facet_search.facet(:brands).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :brand}) } )
        f.push(label: "Status", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end

    def collection_to_json
      collection.map{|portfolio| {
        :id => portfolio.id,
        :name => portfolio.name,
        :description => portfolio.description,
        :status => portfolio.status,
        :active => portfolio.active?,
        :links => {
            edit: edit_brand_portfolio_path(portfolio),
            show: brand_portfolio_path(portfolio),
            activate: activate_brand_portfolio_path(portfolio),
            deactivate: deactivate_brand_portfolio_path(portfolio)
        }
      }}
    end
end
