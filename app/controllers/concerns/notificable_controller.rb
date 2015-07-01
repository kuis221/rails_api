module NotificableController
  extend ActiveSupport::Concern

  included do
    after_action :remove_resource_new_notifications, only: [:index, :show]
  end

  def remove_resource_new_notifications
    # To avoid double render error in index action
    return if action_name == 'index' && @class_name.blank?
    @class_name = resource.class.name.underscore unless @class_name.present?
    send "remove_#{@class_name}_notifications"
  end

  # Remove the notifications related to new events (including for teams)
  # and keep the notifications for new tasks associated to the event and user
  def remove_event_notifications
    notifications = current_company_user.notifications.where('message = ? OR message = ?', 'new_event', 'new_team_event')
    notifications = notifications.where("params->'event_id' = (?)", resource.id.to_s) if action_name == 'show'
    notifications.destroy_all if action_name == 'show' || params[:from_notifications]
  end

  # Remove the notifications related to new campaigns
  def remove_campaign_notifications
    notifications = current_company_user.notifications.new_campaigns
    notifications = notifications.where('params->? = (?)', 'campaign_id', resource.id.to_s) if action_name == 'show'
    notifications.destroy_all if action_name == 'show' || params[:from_notifications]
  end
end
