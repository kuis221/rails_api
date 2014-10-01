class Results::ExpensesController < FilteredController
  defaults resource_class: ::Event
  respond_to :xls, only: :index

  helper_method :expenses_total, :return_path

  private

  def search_params
    @search_params ||= begin
      super
      unless @search_params.key?(:user) && !@search_params[:user].empty?
        @search_params[:with_expenses_only] = true
      end
      @search_params[:event_data_stats] = true
      @search_params
    end
  end

  def expenses_total
    @solr_search.stat_response['stats_fields']['spent_es']['sum'] rescue 0
  end

  def authorize_actions
    authorize! :index_results, EventExpense
  end

  def return_path
    results_reports_path
  end
end
