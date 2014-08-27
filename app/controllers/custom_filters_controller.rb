class CustomFiltersController < InheritedResources::Base

  respond_to :js, only: [:index, :new, :create]

  actions :index, :new, :create

  private
    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(custom_filter: [:id, :company_user_id, :name, :apply_to, :filters])[:custom_filter]
    end
end