class Results::SurveysController < FilteredController
  defaults resource_class: ::Event
  respond_to :xls, only: :index

  helper_method :expenses_total, :return_path

  private

  def search_params
    @search_params ||= begin
      super
      unless @search_params.key?(:user) && !@search_params[:user].empty?
        @search_params[:with_surveys_only] = true
      end
      @search_params
    end
  end

  def authorize_actions
    authorize! :index_results, Survey
  end

  def return_path
    results_reports_path
  end
end
