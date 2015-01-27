class RemoveYelpColumnFromPlaces < ActiveRecord::Migration
  def change
    remove_column :places, :yelp_business_id
  end
end
