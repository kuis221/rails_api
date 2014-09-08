class BrandAmbassadors::VisitsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  include EventsHelper

  helper_method :describe_filters

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

    def describe_filters
      first_part  = "#{describe_date_ranges} #{describe_brands} #{describe_areas}".strip
      first_part = nil if first_part.empty?
      second_part = "#{describe_people}".strip
      second_part = nil if second_part.empty?
      "#{view_context.pluralize(number_with_delimiter(collection_count), "#{describe_status} visit")} #{[first_part, second_part].compact.join(' and ')}"
    end

    def permitted_params
      params.permit(brand_ambassadors_visit: [:name, :description, :start_date, :end_date, :company_user_id])[:brand_ambassadors_visit]
    end

    def build_resource
      @visit || super.tap do |v|
        v.company_user_id ||= current_company_user.id
      end
    end
end
