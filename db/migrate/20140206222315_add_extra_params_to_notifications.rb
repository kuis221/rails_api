class AddExtraParamsToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :extra_params, :text
  end
end
