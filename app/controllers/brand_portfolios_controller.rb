class BrandPortfoliosController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  load_and_authorize_resource except: :index

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
        'active' => { :order => 'brand_portfolios.active' }
      }
    end
end
