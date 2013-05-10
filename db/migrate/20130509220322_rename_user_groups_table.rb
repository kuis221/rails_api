class RenameUserGroupsTable < ActiveRecord::Migration
  def change
    rename_table :user_groups, :roles
    add_column :roles, :company_id, :integer
    remove_index :users, :role_id
    rename_column :users, :role_id, :role_id
    add_index :users, :role_id
    Role.update_all(company_id: Company.first)
  end
end
