class Results::ExpensesController < FilteredController
  defaults resource_class: ::Event
  respond_to :csv, only: :index
  respond_to :zip, only: :index

  helper_method :expenses_total, :return_path

  private

  def collection_to_csv
    export_collection
  end

  def collection_to_zip(export, path)
    Zip::File.open(path, Zip::File::CREATE) do |zipfile|
      csv = export_collection do |event|
        add_expenses_files_zip(event, zipfile)
      end
      add_expenses_csv_file(csv, zipfile)
    end
  end

  def export_collection(&block)
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
        yield event if block_given?
      end
    end
  end

  def export_list(export, path)
    @_export = export
    if export.export_format == 'zip'
      run_callbacks :export do
        collection_to_zip(export, path)
      end
    else
      super
    end
  end

  def add_expenses_files_zip(event, zipfile)
    event.event_expenses.each_with_index do |expense, index|
      file_local_name = "#{Rails.root}/tmp/#{expense.id}"
      expense.receipt.file.copy_to_local_file(:medium, file_local_name) if expense.receipt.present?
      zipfile.add generate_filename(event, expense, index), file_local_name if expense.receipt.present?
    end
  end

  def add_expenses_csv_file(csv, zipfile)
    csv_file = Tempfile.new('expenses')
    csv_file.write csv
    csv_file.close
    zipfile.add "expenses-#{Time.now.strftime('%Y%m%d%H%M%S')}.csv", csv_file.path
  end

  def generate_filename(event, expense, index)
    user = User.find(expense.created_by_id) if expense.created_by_id.present?
    created_name = user.present? ? "#{user.first_name[0]}{user.last_name}": ''
    "#{expense.expense_date.strftime('%Y%m%d')}-#{remove_all_spaces(event.place_name)}-#{remove_all_spaces(expense.category)}-#{created_name}-#{index}.#{expense.receipt.file_extension}"
  end

  def remove_all_spaces(value)
    value.gsub(/\s+/, '')
  end

  def search_params
    @search_params || (super.tap do |p|
      p[:with_expenses_only] = true unless p.key?(:user) && p[:user].present?
      p[:event_data_stats] = true
      p[:sorting] ||= Event.search_start_date_field
      p[:sorting_dir] ||= 'asc'
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
