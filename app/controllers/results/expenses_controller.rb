class Results::ExpensesController < FilteredController
  defaults resource_class: ::Event
  respond_to :csv, only: :index

  helper_method :expenses_total, :return_path

  private

  def collection_to_csv
    exporter = EventExpensesExporter.new(current_company_user, search_params)
    CSV.generate do |csv|
      csv << [
        'CAMPAIGN NAME', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'EVENT START DATE', 'EVENT END DATE',
        'CREATED AT', 'CREATED BY', 'LAST MODIFIED', 'MODIFIED BY'].concat(
          exporter.expenses_columns)
      each_collection_item do |event|
        csv << [
          event.campaign_name, event.place_name, event.place_address, event.country, event.start_date, event.end_date,
          event.first_event_expense_created_at, event.first_event_expense_created_by, event.last_event_expense_updated_at, event.last_event_expense_updated_by
        ].concat(exporter.event_expenses(event))
      end
    end
  end

  def search_params
    @search_params || (super.tap do |p|
      p[:with_expenses_only] = true unless p.key?(:user) && p[:user].present?
      p[:event_data_stats] = true
      p[:search_permission] = :index_results
      p[:search_permission_class] = EventExpense
    end)
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

  def permitted_search_params
    Event.searchable_params
  end
end
