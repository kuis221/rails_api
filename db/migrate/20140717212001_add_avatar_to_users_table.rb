class AddAvatarToUsersTable < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.attachment :avatar
    end
  end
  def down
    remove_column :users, :avatar_file_name
    remove_column :users, :avatar_content_type
    remove_column :users, :avatar_file_size
    remove_column :users, :avatar_updated_at
  end
end
