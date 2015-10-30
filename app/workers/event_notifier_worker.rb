class EventNotifierWorker
  include Sidekiq::Worker
  sidekiq_options queue: :notification

  def perform(event_id)
    event = Event.find(event_id)
    if event.campaign.present?
      event.campaign.all_users_with_access.each do |user|
        if user.allowed_to_access_place?(event.place)
          Notification.new_event(user, event)
        end
      end
    end
  end
end
