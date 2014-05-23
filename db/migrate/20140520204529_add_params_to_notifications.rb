class AddParamsToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :params, :hstore
    add_hstore_index :notifications, :params
    Notification.find_each{|n| n.params = n.extra_params; n.save}
  end
end
