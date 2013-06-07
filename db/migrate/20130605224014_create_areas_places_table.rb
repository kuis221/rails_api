class CreateAreasPlacesTable < ActiveRecord::Migration
  def change
    create_table :areas_places do |t|
      t.references :area
      t.references :place
    end
    add_index :areas_places, :area_id
    add_index :areas_places, :place_id
    add_index :areas_places, [:area_id, :place_id], unique: true
  end
end
