class AddDefaultNotificationsSettingsToUsers < ActiveRecord::Migration
  def change
    CompanyUser.find_each do |u|
      u.set_default_notifications_settings
      u.save
    end
  end
end
