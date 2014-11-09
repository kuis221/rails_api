class AddBrandIdColumnToEventExpenseTable < ActiveRecord::Migration
  def change
    add_column :event_expenses, :brand_id, :integer
    add_index :event_expenses, :brand_id
  end
end
