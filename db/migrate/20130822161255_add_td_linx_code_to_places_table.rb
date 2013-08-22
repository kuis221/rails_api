class AddTdLinxCodeToPlacesTable < ActiveRecord::Migration
  def change
    add_column :places, :td_linx_code, :string
  end
end
