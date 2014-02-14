class AddPlaceIdIndexToPlaceables < ActiveRecord::Migration
  def change
    add_index :placeables, :place_id
  end
end
