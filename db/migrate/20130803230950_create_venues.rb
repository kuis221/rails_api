class CreateVenues < ActiveRecord::Migration
  def change
    create_table :venues do |t|
      t.references :company
      t.references :place
      t.integer :events
      t.decimal :promo_hours, :precision => 8, :scale => 2, :default => 0
      t.integer :impressions
      t.integer :interactions
      t.integer :sampled
      t.decimal :spent, :precision => 10, :scale => 2, :default => 0
      t.integer :score
      t.decimal :avg_impressions, :precision => 8, :scale => 2, :default => 0

      t.timestamps
    end
    add_index :venues, :company_id
    add_index :venues, :place_id
    add_index :venues, [:company_id, :place_id], unique: true
  end
end
