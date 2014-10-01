class PlaceablesController < FilteredController
  respond_to :js, only: [:new]

  belongs_to :campaign, :area, :company_user, :team, polymorphic: true

  skip_authorize_resource

  before_action :authorize_parent

  def new
    @areas = current_company.areas.active.where('areas.id not in (?)', parent.area_ids + [0]).order('name ASC')
  end

  def add_area
    authorize!(:add_place, parent)
    @area = current_company.areas.find(params[:area])
    unless parent.area_ids.include?(@area.id)
      parent.areas << @area
    end
  end

  def remove_area
    authorize!(:remove_place, parent)
    @area = current_company.areas.find(params[:area])
    if parent.area_ids.include?(@area.id)
      parent.areas.destroy @area
    end
  end

  private

  def authorize_parent
    can?(:show, parent)
  end
end
