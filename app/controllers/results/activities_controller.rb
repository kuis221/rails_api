class Results::ActivitiesController < FilteredController
  respond_to :xls, :pdf, only: :index

  private

  def authorize_actions
    authorize! :index_results, Activity
  end

  def facets
    @facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      f.push build_activity_type_bucket
      f.push build_campaign_bucket
    end
  end

  def return_path
    results_reports_path
  end
end
