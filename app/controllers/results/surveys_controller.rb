class Results::SurveysController < FilteredController
  defaults resource_class: ::Event
  respond_to :xls, only: :index

  helper_method :expenses_total, :return_path

  private

  def search_params
    @search_params || (super.tap do |p|
      p[:with_surveys_only] = true unless p.key?(:user) && !p[:user].empty?
    end)
  end

  def authorize_actions
    authorize! :index_results, Survey
  end

  def return_path
    results_reports_path
  end

  def permitted_search_params
    Event.searchable_params
  end
end
