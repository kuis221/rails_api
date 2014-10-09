class UpdateNotificationIcons < ActiveRecord::Migration
  def change
    Notification.where(icon: 'event').update_all(icon: 'events')
    Notification.where(icon: 'task').update_all(icon: 'tasks')
  end
end
