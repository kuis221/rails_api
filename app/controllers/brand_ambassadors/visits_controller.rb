class BrandAmbassadors::VisitsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, only: :index

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Venue, Area],
      people: [CompanyUser]
    })
    render :json => buckets.flatten
  end

  protected
    def permitted_params
      params.permit(brand_ambassadors_visit: [:name, :start_date, :end_date, :company_user_id])[:brand_ambassadors_visit]
    end

    def build_resource
      @visit || super.tap do |v|
        v.company_user_id ||= current_company_user.id
      end
    end
end
