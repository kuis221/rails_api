class BrandsController < FilteredController
  actions :index
  belongs_to :campaign
  respond_to :json, only: [:index]
end
