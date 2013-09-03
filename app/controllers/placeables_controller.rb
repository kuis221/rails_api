class PlaceablesController < FilteredController
  respond_to :js, only: [:new, :create, :destroy]

  belongs_to :campaign, :area, :company_user, :team, polymorphic: true


  def new
    @areas = current_company.areas
  end
end
