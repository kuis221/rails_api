class AddDescriptionColumnToRolesTable < ActiveRecord::Migration
  def change
    add_column :roles, :description, :text
  end
end
