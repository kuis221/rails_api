class AddWebAddressToVenues < ActiveRecord::Migration
  def up
    add_column :venues, :web_address, :string
  end
  def down
    remove_column :venues, :web_address
  end
end
