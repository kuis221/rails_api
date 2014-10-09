class AlterExpenseTable < ActiveRecord::Migration
  def up
    EventExpense.all.each do |expense|
      tries = 15
      begin
        AttachedAsset.create(attachable: expense, file: expense.file, asset_type: 'expense', processed: true) if expense.file.exists?
      rescue AWS::S3::Errors::RequestTimeout => e
        sleep(3 + (15 - tries))
        p "Failed... #{tries} tries left!"
        retry unless (tries -= 1) <= 0
        raise e
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
