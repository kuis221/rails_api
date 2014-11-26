class Results::ExpensesController < FilteredController
  defaults resource_class: ::Event
  respond_to :xls, only: :index

  helper_method :expenses_total, :return_path

  private

  def search_params
    @search_params || super.tap do |p|
      p[:with_expenses_only] = true unless p.key?(:user) && p[:user].present?
      p[:event_data_stats] = true
    end
  end

  def expenses_total
    collection_search.stat_response['stats_fields']['spent_es']['sum'] rescue 0
  end

  def authorize_actions
    authorize! :index_results, EventExpense
  end

  def return_path
    results_reports_path
  end
end
