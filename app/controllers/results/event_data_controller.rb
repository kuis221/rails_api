
class Results::EventDataController < FilteredController
  defaults resource_class: ::Event

  helper_method :data_totals, :return_path

  private

  def collection_to_csv
    exporter = FormFieldDataExporter.new(current_company_user, search_params, resource_class)
    expense_exporter = EventExpensesExporter.new(current_company_user, search_params)
    CSV.generate do |csv|
      csv << [
        'CAMPAIGN NAME', 'AREAS', 'TD LINX CODE', 'VENUE NAME', 'ADDRESS', 'COUNTRY',
        'CITY', 'STATE', 'ZIP', 'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS',
        'CONTACTS', 'URL', 'START', 'END', 'SUBMITTED AT', 'APPROVED AT', 'PROMO HOURS'
      ].concat(expense_exporter.expenses_columns + exporter.custom_fields_to_export_headers)
      each_collection_item do |event|
        csv << [
          event.campaign_name, exporter.area_for_event(event),
          event.place_td_linx_code, event.place_name, event.place_address, event.country,
          event.place_city, event.place_state, event.place_zipcode, event.status,
          event.event_status, event.team_members, event.contacts, event.url,
          event.start_date, event.end_date, event.submitted_date, event.approved_date, event.promo_hours].concat(
            expense_exporter.event_expenses(event).concat(
              exporter.custom_fields_to_export_values(event)))
      end
    end
  end

  def data_totals
    @data_totals ||= Hash.new.tap do |totals|
      totals['events_count'] = collection_search.total
      totals['promo_hours'] = collection_search.stat_response['stats_fields']['promo_hours_es']['sum'] rescue 0
      totals['impressions'] = collection_search.stat_response['stats_fields']['impressions_es']['sum'] rescue 0
      totals['interactions'] = collection_search.stat_response['stats_fields']['interactions_es']['sum'] rescue 0
      totals['photos'] = collection_search.stat_response['stats_fields']['photos_es']['sum'] rescue 0
      totals['samples'] = collection_search.stat_response['stats_fields']['samples_es']['sum'] rescue 0
      totals['spent'] = collection_search.stat_response['stats_fields']['spent_es']['sum'] rescue 0
      totals['gender_female'] = collection_search.stat_response['stats_fields']['gender_female_es']['mean'] rescue 0
      totals['gender_male'] = collection_search.stat_response['stats_fields']['gender_male_es']['mean'] rescue 0
      totals['ethnicity_asian'] = collection_search.stat_response['stats_fields']['ethnicity_asian_es']['mean'] rescue 0
      totals['ethnicity_black'] = collection_search.stat_response['stats_fields']['ethnicity_black_es']['mean'] rescue 0
      totals['ethnicity_hispanic'] = collection_search.stat_response['stats_fields']['ethnicity_hispanic_es']['mean'] rescue 0
      totals['ethnicity_native_american'] = collection_search.stat_response['stats_fields']['ethnicity_native_american_es']['mean'] rescue 0
      totals['ethnicity_white'] = collection_search.stat_response['stats_fields']['ethnicity_white_es']['mean'] rescue 0
    end
  end

  def search_params
    @search_params || (super.tap do |p|
      p[:search_permission] = :index_results
      p[:search_permission_class] = EventData
      p[:event_data_stats] = true
    end)
  end

  def authorize_actions
    authorize! :index_results, EventData
  end

  def return_path
    results_reports_path
  end

  def permitted_search_params
    Event.searchable_params
  end
end
