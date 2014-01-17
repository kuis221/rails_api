class AddIndexToPlaceablesTable < ActiveRecord::Migration
  def change
    add_index :placeables, [:placeable_id, :placeable_type]
  end
end
