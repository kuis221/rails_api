class CreateTableBrandsEvents < ActiveRecord::Migration
  def change
    create_table :brands_events do |t|
      t.references :brand
      t.references :event
    end
    add_index :brands_events, :brand_id
    add_index :brands_events, :event_id
    add_index :brands_events, [:brand_id, :event_id], unique: true
  end
end
