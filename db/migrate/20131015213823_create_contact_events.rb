class CreateContactEvents < ActiveRecord::Migration
  def change
    create_table :contact_events do |t|
      t.references :contact
      t.references :event

      t.timestamps
    end
    add_index :contact_events, :contact_id
    add_index :contact_events, :event_id
  end
end
