class AddNotificationsSettingsToCompanyUsers < ActiveRecord::Migration
  def change
    add_column :company_users, :notifications_settings, :string, array: true, default: []
  end
end
