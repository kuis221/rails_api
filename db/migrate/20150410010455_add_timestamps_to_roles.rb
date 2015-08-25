class AddTimestampsToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :created_by_id, :integer
    add_column :roles, :updated_by_id, :integer
  end
end
