class AddNeighborhoodToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :neighborhood, :string
  end
end
