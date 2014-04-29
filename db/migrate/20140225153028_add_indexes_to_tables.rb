class AddIndexesToTables < ActiveRecord::Migration
  def change
    add_index :events, :aasm_state
    add_index :places, :state
    add_index :places, :country
    add_index :places, :city
  end
end
