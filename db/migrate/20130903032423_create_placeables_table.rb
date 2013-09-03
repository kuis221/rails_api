class CreatePlaceablesTable < ActiveRecord::Migration
  def up
    create_table :placeables do |t|
      t.references :place
      t.references :placeable, polymorphic: true
    end
    execute 'insert into placeables (place_id, placeable_id, placeable_type) (select place_id, area_id, \'Area\' from areas_places)'
    drop_table :areas_places
  end

  def down
  end
end
