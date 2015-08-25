class AddPriceLevelToVenues < ActiveRecord::Migration
  def up
    add_column :venues, :place_price_level, :integer
  end
  def down
    remove_column :venues, :place_price_level
  end
end
