class AddNewColumnsToEventExpenses < ActiveRecord::Migration
  def change
    add_column :event_expenses, :category, :string
    add_column :event_expenses, :expense_date, :date
    add_column :event_expenses, :reimbursable, :boolean
    add_column :event_expenses, :billable, :boolean
    add_column :event_expenses, :merchant, :string
    add_column :event_expenses, :description, :text

    # Set the default expense date
    EventExpense.update_all('expense_date=e.start_at FROM events e WHERE e.id=event_expenses.event_id')

    # Update the expenses for Legacy
    ['Bar Spend', 'Tip', 'Supplies'].each do |category|
      EventExpense.joins(:event)
        .merge(Event.in_company([2, 7]))
        .where('name ilike ?', "%#{category}%")
        .update_all(category: category, name: nil)
    end
    EventExpense.joins(:event)
      .merge(Event.in_company([2, 7]))
      .where(category: nil)
      .update_all(category: 'Other')

    # Update the category for non legacy companies
    EventExpense.joins(:event)
      .where.not(events: { company_id: [2, 7] })
      .update_all('category=name')
  end
end
