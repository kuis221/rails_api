class AddNewColumnsToEventExpenses < ActiveRecord::Migration
  def change
    add_column :event_expenses, :category, :string
    add_column :event_expenses, :expense_date, :date
    add_column :event_expenses, :reimbursable, :boolean
    add_column :event_expenses, :billable, :boolean
    add_column :event_expenses, :merchant, :string
    add_column :event_expenses, :description, :text
  end
end
