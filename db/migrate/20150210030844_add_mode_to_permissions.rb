class AddModeToPermissions < ActiveRecord::Migration
  def up
    add_column :permissions, :mode, :string, default: :none
    execute 'UPDATE permissions SET mode=\'campaigns\''
    Rails.cache.clear
  end

  def down
    remove_column :permissions, :mode
    Rails.cache.clear
  end
end
