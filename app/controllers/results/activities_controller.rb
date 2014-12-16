module Results
  class ActivitiesController < FilteredController
    respond_to :xls, :pdf, only: :index

    private

    def authorize_actions
      authorize! :index_results, Activity
    end

    def return_path
      results_reports_path
    end

    def permitted_search_params
      Event.searchable_params + [activity_type: []]
    end
  end
end
