class AlterExpenseTable < ActiveRecord::Migration
  def up
    EventExpense.all.each do |expense|
      tries = 3
      begin
        AttachedAsset.create({attachable: expense, file: expense.file, asset_type: 'expense', processed: true}, without_protection: true) if expense.file.exists?
      rescue AWS::S3::Errors::RequestTimeout
        retry unless (tries -= 1) <= 0
        raise "Cannot save attached asset for #{expense.inspect}"
      end
      expense.file = nil
      expense.save
    end
    remove_column :event_expenses, :file_file_name
    remove_column :event_expenses, :file_content_type
    remove_column :event_expenses, :file_file_size
    remove_column :event_expenses, :file_updated_at
  end

  def down
  end
end
