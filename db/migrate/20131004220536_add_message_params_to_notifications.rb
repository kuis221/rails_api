class AddMessageParamsToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :message_params, :text
  end
end
