class AddFieldsToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :price_level, :integer, default: nil
    add_column :places, :phone_number, :string, default: nil
  end
end
