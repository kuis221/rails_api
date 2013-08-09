class CreateEventExpenses < ActiveRecord::Migration
  def change
    create_table :event_expenses do |t|
      t.references :event
      t.string :name
      t.decimal :amount, :precision => 9, :scale => 2, :default => 0
      t.attachment :file
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
    add_index :event_expenses, :event_id
  end
end
