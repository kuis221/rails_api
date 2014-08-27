class BrandAmbassadors::VisitsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  #defaults :resource_class => BrandAmbassadors::Visit

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  protected
    def permitted_params
      params.permit(brand_ambassadors_visit: [:name, :start_date, :end_date, :company_user_id])[:brand_ambassadors_visit]
    end
end
