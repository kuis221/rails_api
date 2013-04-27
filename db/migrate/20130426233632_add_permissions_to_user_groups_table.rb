class AddPermissionsToUserGroupsTable < ActiveRecord::Migration
  def change
    add_column :user_groups, :permissions, :text
  end
end
