class AddMergeFlagToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :merged_with_place_id, :integer
  end
end
