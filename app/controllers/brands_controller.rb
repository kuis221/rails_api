class BrandsController < FilteredController
  actions :index
  belongs_to :campaign, :brand_portfolio, optional: true
  respond_to :json, only: [:index]

  has_scope :with_text

  private

    def collection_to_json
      collection.map{|brand| {
        :id => brand.id,
        :name => brand.name,
        :links => {
            delete:'#'
        }
      }}
    end
end
