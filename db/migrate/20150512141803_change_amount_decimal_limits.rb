class ChangeAmountDecimalLimits < ActiveRecord::Migration
  def change
    change_column :event_expenses, :amount, :decimal, precision: 15, scale: 2
  end
end
