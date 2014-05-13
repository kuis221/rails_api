class CreateIndexNotificationsOnMessage < ActiveRecord::Migration
  def change
    add_index :notifications, :message
  end
end
