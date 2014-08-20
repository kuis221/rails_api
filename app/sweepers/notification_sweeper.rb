class NotificationSweeper < ActionController::Caching::Sweeper
  observe Notification

  def after_save(notification)
    expire_cache_notifications(notification)
  end

  def after_destroy(notification)
    expire_cache_notifications(notification)
  end

  private
    def expire_cache_notifications(notification)
      Rails.cache.delete "user_notifications_#{notification.company_user_id}"
    end
end