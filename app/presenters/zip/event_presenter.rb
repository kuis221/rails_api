module Zip
  class EventPresenter < Csv::EventPresenter
    def receipts_for_zip_export
      @model.event_expenses.includes(:creator).each_with_index.inject([]) do |m, (expense, index)|
        if expense.receipt.present?
          file_local_name = "#{Rails.root}/tmp/#{expense.id}"
          style = expense.receipt.image? ? :medium : :original
          next unless expense.receipt.file.path(style).present?
          tmp_file = expense.receipt.file.copy_to_local_file(style, file_local_name)
          m << [sanitize_filename(generate_filename(expense, index)), file_local_name] if tmp_file.present?
        end
        m
      end
    end

    def generate_filename(expense, index)
      created_name = expense.creator.present? ? "#{expense.creator.first_name[0]}#{expense.creator.last_name}": ''
      expense_date = expense.expense_date.strftime('%Y%m%d')
      venue_name = remove_all_spaces(@model.place_name)
      category = remove_all_spaces(expense.category)
      file_extension = expense.receipt.file_extension
      "#{expense_date}-#{venue_name}-#{category}-#{created_name}-#{index}#{expense.id}.#{file_extension}"
    end

    def remove_all_spaces(value)
      value.gsub(/\s+/, '') if value.present?
    end

    def sanitize_filename(filename)
      fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
      fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }
      return fn.join '.'
    end
  end
end