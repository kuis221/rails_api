class AddNotificationsSettingsToCompanyUsers < ActiveRecord::Migration
  def change
    add_column :company_users, :notifications_settings, :text, array: true, default: '{}'
  end
end
