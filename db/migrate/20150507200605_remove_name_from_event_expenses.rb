class RemoveNameFromEventExpenses < ActiveRecord::Migration
  def up
    EventExpense.update_all('category=name')
    remove_column :event_expenses, :name, :string
  end
  def down
    add_column :event_expenses, :name, :string
    EventExpense.update_all('name=category')
  end
end
