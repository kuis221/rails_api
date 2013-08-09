class CreateEventData < ActiveRecord::Migration
  def change
    create_table :event_data do |t|
      t.references :event
      t.integer :impressions, :default => 0
      t.integer :interactions, :default => 0
      t.integer :samples, :default => 0
      t.decimal :gender_female, :precision => 5, :scale => 2, :default => 0
      t.decimal :gender_male, :precision => 5, :scale => 2, :default => 0
      t.decimal :ethnicity_asian, :precision => 5, :scale => 2, :default => 0
      t.decimal :ethnicity_black, :precision => 5, :scale => 2, :default => 0
      t.decimal :ethnicity_hispanic, :precision => 5, :scale => 2, :default => 0
      t.decimal :ethnicity_native_american, :precision => 5, :scale => 2, :default => 0
      t.decimal :ethnicity_white, :precision => 5, :scale => 2, :default => 0
      t.decimal :cost, :precision => 10, :scale => 2, :default => 0

      t.timestamps
    end
    add_index :event_data, :event_id
  end
end
