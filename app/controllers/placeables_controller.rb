class PlaceablesController < FilteredController
  respond_to :js, only: [:new, :create]

  belongs_to :campaign, :area, :company_user, :team, polymorphic: true


  def new
    @areas = current_company.areas.where('areas.id not in (?)', parent.area_ids + [])
  end
end
