class AddExpenseCategoriesToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :expense_categories, :text
  end
end
