class BrandsController < FilteredController
  actions :index, :new, :create
  belongs_to :campaign, :brand_portfolio, optional: true
  respond_to :json, only: [:index]
  respond_to :js, only: [:new, :create]

  has_scope :with_text
  has_scope :not_in_portfolio

  def create
    create! do |success, failure|
      success.js do
          parent.brands << resource if parent? and parent
          render :create
      end
    end
  end
end
