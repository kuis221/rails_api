class BrandPortfoliosController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions member: [:select_brands, :add_brands]

  load_and_authorize_resource except: :index

  def autocomplete
    buckets = []

    # Search brands
    search = Sunspot.search(Brand, BrandPortfolio) do
      keywords(params[:q]) do
        fields(:name)
      end
    end
    buckets.push(label: "Brands", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

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
    def collection_to_json
      collection.map{|portfolio| {
        :id => portfolio.id,
        :name => portfolio.name,
        :description => portfolio.description,
        :status => portfolio.active? ? 'Active' : 'Inactive',
        :active => portfolio.active?,
        :links => {
            edit: edit_brand_portfolio_path(portfolio),
            show: brand_portfolio_path(portfolio),
            activate: activate_brand_portfolio_path(portfolio),
            deactivate: deactivate_brand_portfolio_path(portfolio)
        }
      }}
    end

    def sort_options
      {
        'name' => { :order => 'brand_portfolios.name' },
        'description' => { :order => 'brand_portfolios.description' },
        'status' => { :order => 'brand_portfolios.active' }
      }
    end
end
