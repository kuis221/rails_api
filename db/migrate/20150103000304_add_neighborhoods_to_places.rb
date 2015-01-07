class AddNeighborhoodsToPlaces < ActiveRecord::Migration
  def up
    add_column :places, :neighborhoods, :string, array: true
    add_column :places, :yelp_business_id, :string
    execute 'UPDATE places set neighborhood=NULL'
    remove_column :places, :neighborhood
  end

  def down
    remove_column :places, :neighborhoods
    remove_column :places, :yelp_business_id
    add_column :places, :neighborhood, :string
  end
end
