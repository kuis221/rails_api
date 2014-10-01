# Custom Filters Controller class
#
# This class handle the requests for managing the Custom Filters
#
class CustomFiltersController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create, :destroy]

  actions :index, :new, :create, :destroy

  private

  def build_resource_params
    [permitted_params || {}]
  end

  def begin_of_association_chain
    current_company_user
  end

  def permitted_params
    params.permit(custom_filter: [:id, :name, :group, :apply_to, :filters])[:custom_filter]
  end
end
