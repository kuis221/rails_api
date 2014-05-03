class AddActiveToBrand < ActiveRecord::Migration
  def change
    add_column :brands, :active, :boolean, default: true
  end
end
