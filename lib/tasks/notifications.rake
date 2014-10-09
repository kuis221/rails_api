namespace :notifications do

  desc 'Send SMS notifications to users with late/due events'
  task late_events: :environment do
    Notification.send_late_event_sms_notifications
  end

end
