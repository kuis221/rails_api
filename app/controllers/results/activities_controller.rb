module Results
  class ActivitiesController < FilteredController
    respond_to :xls, :pdf, only: :index

    private

    def authorize_actions
      authorize! :index_results, Activity
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        f.push build_activity_type_bucket
        f.push build_brands_bucket
        f.push build_campaign_bucket
        f.push build_areas_bucket
        f.push build_users_bucket
        f.push build_state_bucket
        f.concat build_custom_filters_bucket
      end
    end

    def return_path
      results_reports_path
    end

    def permitted_search_params
      Event.searchable_params + [activity_type: []]
    end
  end
end
