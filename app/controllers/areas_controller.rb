# Areas Controller class
#
# This class handle the requests for managing the Areas
class AreasController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :json, only: [:cities]
  respond_to :xls, :pdf, only: :index

  helper_method :assignable_areas

  belongs_to :place, :campaign, :company_user, optional: true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController

  skip_load_and_authorize_resource only: [:assign, :unassign, :select_form]

  custom_actions member: [:select_places, :add_places, :add_to_campaign]

  def create
    create! do |success, _|
      success.js do
        parent.areas << resource if parent? && parent
        render :create
      end
    end
  end

  def cities
    render json: resource.cities.map(&:name)
  end

  def select_form
    authorize!(:add_place, parent)
  end

  def assign
    authorize!(:add_place, parent)
    parent.areas << current_company.areas.find(params[:id])
  end

  def unassign
    authorize!(:remove_place, parent)
    parent.areas.destroy resource
  end

  private

  def assignable_areas
    @assignable_areas ||= current_company.areas.active.where('areas.id not in (?)', parent.area_ids + [0]).order('name ASC')
  end

  def permitted_params
    params.permit(area: [:name, :description])[:area]
  end
end
