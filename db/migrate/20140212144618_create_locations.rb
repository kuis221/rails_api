class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :path, limit: 500
    end

    create_table :locations_places do |t|
      t.references :location
      t.references :place
    end

    add_column :places, :location_id, :integer
    add_column :places, :is_location, :boolean

    add_index :locations, :path, unique: true
  end
end
