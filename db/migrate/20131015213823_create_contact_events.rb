class CreateContactEvents < ActiveRecord::Migration
  def change
    create_table :contact_events do |t|
      t.references :event
      t.integer :contactable_id
      t.string :contactable_type

      t.timestamps
    end
    add_index :contact_events, [:contactable_id, :contactable_type]
    add_index :contact_events, :event_id
  end
end
