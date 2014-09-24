# Brand Portfolios Controller class
#
# This class handle the requests for managing the Brand Portfolios
#
class BrandPortfoliosController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update, :brands, :delete_brand, :select_brands]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions resource: [:select_brands, :add_brands]

  def autocomplete
    buckets = autocomplete_buckets(
      brands: [Brand, BrandPortfolio]
    )
    render json: buckets.flatten
  end

  def add_brands
    @brand = current_company.brands.find(params[:brand_id])
    return if resource.brands.exists?(params[:brand_id])
    resource.brands << @brand
    resource.solr_index
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
      facet_params = HashWithIndifferentAccess.new(search_params.select do |k, _|
        %w(q company_id).include?(k)
      end)
      facet_search = resource_class.do_search(facet_params, true)

      f.push build_brand_bucket facet_search
      f.push(label: 'Active State', items: %w(Active Inactive).map do |x|
        build_facet_item(label: x, id: x, name: :status, count: 1)
      end)
    end
  end

  def build_brand_bucket(facet_search)
    items = facet_search.facet(:brands).rows.map do |x|
      id, name = x.value.split('||')
      build_facet_item(label: name, id: id, count: x.count, name: :brand)
    end
    items = items.sort { |a, b| a[:label] <=> b[:label] }
    { label: 'Brands', items: items }
  end
end
