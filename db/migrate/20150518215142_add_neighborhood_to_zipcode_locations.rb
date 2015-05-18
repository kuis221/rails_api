class AddNeighborhoodToZipcodeLocations < ActiveRecord::Migration
  def change
    add_column :zipcode_locations, :neighborhood_id, :integer
  end
end
