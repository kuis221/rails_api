module NotificableController
  extend ActiveSupport::Concern

  included do
    after_action :remove_resource_new_notifications, only: :show
  end

  def remove_resource_new_notifications
    send "remove_#{resource.class.name.underscore}_notification"
  end

  # Remove the notifications related to new events (including for teams)
  # and keep the notifications for new tasks associated to the event and user
  def remove_event_notification
    current_company_user.notifications
      .where('message = ? OR message = ?', 'new_event', 'new_team_event')
      .where("params->'event_id' = (?)", resource.id.to_s).destroy_all
  end

  # Remove the notifications related to new campaigns
  def remove_campaign_notification
    current_company_user.notifications.new_campaigns
      .where('params->? = (?)', 'campaign_id', resource.id.to_s).destroy_all
  end
end
