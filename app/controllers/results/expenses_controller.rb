class Results::ExpensesController < FilteredController
  defaults resource_class: ::Event
  respond_to :xls, only: :index

  helper_method :expenses_total, :return_path

  private

  def collection_to_csv
    CSV.generate do |csv|
      csv << [
        'CAMPAIGN NAME', 'BRAND', 'VENUE NAME', 'ADDRESS', 'EXPENSE DATE',
        'EVENT START DATE', 'EVENT END DATE', 'AMOUNT', 'CATEGORY', 'REIMBURSABLE', 'BILLABLE',
        'MERCHANT', 'DESCRIPTION', 'ACTIVE STATE']
      each_collection_item do |event|
        csv << [
          event.campaign_name, exporter.area_for_event(event), event.place_td_linx_code,
          event.place_name, event.place_address, event.place_city, event.place_state,
          event.place_zipcode, event.status, event.event_status, event.team_members,
          event.contacts, event.url, event.start_date, event.end_date, event.promo_hours,
          event.spent] +
          exporter.custom_fields_to_export_values(event)
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
