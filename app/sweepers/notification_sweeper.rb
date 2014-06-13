class NotificationSweeper < ActionController::Caching::Sweeper
  observe Notification

  def after_save(notification)
    instantiate_controller
    expire_cache_notifications(notification)
  end

  def after_destroy(notification)
    instantiate_controller
    expire_cache_notifications(notification)
  end

  private
    def expire_cache_notifications(notification)
      expire_action(controller: "company_users", action: "notifications", company_user_id: notification.company_user_id, format: :json)
    end

    def instantiate_controller
      @controller ||= ApplicationController.new
      if @controller.request.nil?
        @controller.request = ActionDispatch::TestRequest.new
        @controller.request.host = Rails.application.routes.default_url_options[:host]
        if Rails.application.routes.default_url_options[:port].present?
          @controller.request.host += ":#{Rails.application.routes.default_url_options[:port]}"
        end
      end
    end
end