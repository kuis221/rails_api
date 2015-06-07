class RemoveNameFromEventExpenses < ActiveRecord::Migration
  def up
    remove_column :event_expenses, :name, :string
  end
  def down
    add_column :event_expenses, :name, :string
  end
end
