class AddIndexOnPlacesName < ActiveRecord::Migration
  def change
    add_index :places, :name
  end
end
