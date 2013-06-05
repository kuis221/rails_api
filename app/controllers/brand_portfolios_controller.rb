class BrandPortfoliosController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions member: [:select_brands, :add_brands]

  load_and_authorize_resource except: :index

  def select_brands
  end

  def add_brands
    @brand = Brand.find(params[:brand_id])
    unless resource.brand_ids.include?(@brand.id)
      resource.brands << @brand
    end
  end

  def delete_brand
    @brand = Brand.find(params[:brand_id])
    resource.brands.delete(@brand)
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
