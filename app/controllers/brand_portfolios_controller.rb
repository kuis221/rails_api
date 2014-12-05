# Brand Portfolios Controller class
#
# This class handle the requests for managing the Brand Portfolios
#
class BrandPortfoliosController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update, :brands, :delete_brand, :select_brands]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions resource: [:select_brands, :add_brands]

  def autocomplete
    buckets = autocomplete_buckets(
      brands: [Brand, BrandPortfolio],
      active_state: []
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
      f.push build_brands_bucket
      f.push build_state_bucket
      f.concat build_custom_filters_bucket
    end
  end

  def permitted_search_params
    [:page, :sorting, :sorting_dir, :per_page,
    brand: [], brand_portfolio: [], status: []]
  end
end
