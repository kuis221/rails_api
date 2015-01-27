class AddNeighborhoodsToPlaces < ActiveRecord::Migration
  def up
    add_column :places, :neighborhoods, :string, array: true
    add_column :places, :yelp_business_id, :string
    execute 'UPDATE places set neighborhoods=NULL'
    execute 'ALTER TABLE places DROP COLUMN neighborhood'
  end

  def down
    remove_column :places, :neighborhoods
    remove_column :places, :yelp_business_id
    add_column :places, :neighborhood, :string
  end
end
