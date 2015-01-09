# Custom Filters Controller class
#
# This class handle the requests for managing the Custom Filters
#
class CustomFiltersController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create, :destroy]
  respond_to :json, only: [:default_view]

  actions :index, :new, :create, :destroy, :update

  def create
    if permitted_params[:id]
      params[:id] = permitted_params[:id]
      update!
    else
      create!
    end
  end

  def default_view
    begin_of_association_chain.custom_filters.where(apply_to: resource.apply_to).update_all("default_view = false")
    resource.update_attribute(:default_view, true)
    render json: { result: 'OK' }
  end

  private

  def build_resource_params
    [permitted_params || {}]
  end

  def begin_of_association_chain
    current_company_user
  end

  def permitted_params
    params.permit(custom_filter: [
      :id, :name, :group, :apply_to, :filters, :default_view])[:custom_filter]
  end
end
