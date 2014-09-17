class BrandAmbassadors::VisitsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  include EventsHelper

  helper_method :describe_filters, :brand_ambassadors_users

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

    def brand_ambassadors_users
      @brand_ambassadors_users ||= begin
        s = current_company.company_users.active
        s = s.where(role_id: current_company.brand_ambassadors_role_ids) if current_company.brand_ambassadors_role_ids.any?
        s
      end
    end

    def build_brand_ambassadors_bucket
      status = current_company_user.filter_settings_for('users', filter_settings_scope)
      users = brand_ambassadors_users.where("company_users.active in (?)", status).
        joins(:user).order('2 ASC').
        pluck('company_users.id, users.first_name || \' \' || users.last_name as name').map do |r|
          build_facet_item({label: r[1], id: r[0], name: :user, count: 1})
      end
      {label: 'Brand Ambassadors', items: users}
    end

    # Returns the facets for the events controller
    def facets
      @events_facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search

        f.push build_brand_ambassadors_bucket
        f.push build_areas_bucket
        f.push build_brands_bucket
        f.push build_state_bucket

        f.push build_custom_filters_bucket
      end
    end
end
