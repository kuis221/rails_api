module Zip
  class EventPresenter < Csv::EventPresenter
    def receipts_for_zip_export
      @model.event_expenses.each_with_index.inject([]) do |m, (expense, index)|
        file_local_name = "#{Rails.root}/tmp/#{expense.id}"
        resolution = expense.receipt.is_thumbnable? ? :medium : :original
        expense.receipt.file.copy_to_local_file(resolution, file_local_name) if expense.receipt.present?
        m << [generate_filename(expense, index), file_local_name] if expense.receipt.present?
        m
      end
    end

    def generate_filename(expense, index)
      user = User.find(expense.created_by_id) if expense.created_by_id.present?
      created_name = user.present? ? "#{user.first_name[0]}#{user.last_name}": ''
      expense_date = expense.expense_date.strftime('%Y%m%d')
      venue_name = remove_all_spaces(@model.place_name)
      category = remove_all_spaces(expense.category)
      file_extension = expense.receipt.file_extension
      "#{expense_date}-#{venue_name}-#{category}-#{created_name}-#{index}.#{file_extension}"
    end

    def remove_all_spaces(value)
      value.gsub(/\s+/, '') if value.present?
    end
  end
end