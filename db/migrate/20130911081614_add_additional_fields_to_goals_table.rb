class AddAdditionalFieldsToGoalsTable < ActiveRecord::Migration
  def change
    add_column :goals, :title, :string
    add_column :goals, :start_date, :date
    add_column :goals, :due_date, :date
  end
end
