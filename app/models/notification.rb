# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  message         :string(255)
#  level           :string(255)
#  path            :text
#  icon            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  message_params  :text
#  extra_params    :text
#  params          :hstore
#

class Notification < ActiveRecord::Base
  belongs_to :company_user

  EVENT_ALERT_POLICY_TEAM = 1 # Notify only to users in the event team
  EVENT_ALERT_POLICY_ALL = 2  # Notify only to ALL users that can access the event

  serialize :message_params
  serialize :extra_params

  scope :new_tasks, -> { where(message: 'new_task').where("params ? 'task_id'") }
  scope :new_events, -> { where(message: 'new_event').where("params ? 'event_id'") }
  scope :new_team_events, -> { where(message: 'new_team_event').where("params ? 'event_id'") }
  scope :new_campaigns, -> { where(message: 'new_campaign').where("params ? 'campaign_id'") }

  scope :grouped_notifications, -> {
    where(message: ['new_event', 'new_team_event', 'new_campaign', 'new_task', 'new_team_task'])
  }

  scope :except_grouped_notifications, -> {
    where('message not in (?)', ['new_event', 'new_team_event', 'new_campaign', 'new_task', 'new_team_task'])
  }

  def self.new_campaign(user, campaign)
    path = Rails.application.routes.url_helpers.campaign_path(campaign)
    if user.notifications.where(path: path).count == 0
      if user.allow_notification?('new_campaign_sms')
        sms_message = I18n.translate("notifications_sms.new_campaign", url: Rails.application.routes.url_helpers.campaign_url(campaign))
        Resque.enqueue(SendSmsWorker, user.phone_number, sms_message)
      end
      if user.allow_notification?('new_campaign_email')
        email_message = I18n.translate("notifications_email.new_campaign", url: Rails.application.routes.url_helpers.campaign_url(campaign))
        UserMailer.notification(user.id, I18n.translate("notification_types.new_campaign"), email_message).deliver
      end
      notification = user.notifications.create(path: path, level: 'grey', message: 'new_campaign', icon: 'campaign', params: {campaign_id: campaign.id})
    end
  end

  def self.new_event(user, event, team = nil)
    path = Rails.application.routes.url_helpers.event_path(event)
    if user.notifications.where(path: path).count == 0
      message = team.present? ? 'new_team_event' : 'new_event'
      message_params = team.present? ? {team_id: team.id, team_name: team.name} : nil
      if user.allow_notification?('new_event_team_sms')
        sms_message = I18n.translate("notifications_sms.new_event", url: Rails.application.routes.url_helpers.event_url(event))
        Resque.enqueue(SendSmsWorker, user.phone_number, sms_message)
      end
      if user.allow_notification?('new_event_team_email')
        email_message = I18n.translate("notifications_email.new_event", url: Rails.application.routes.url_helpers.event_url(event))
        UserMailer.notification(user.id, I18n.translate("notification_types.new_event"), email_message).deliver
      end
      notification = user.notifications.create(path: path, level: 'grey', message: message, icon: 'event', message_params: message_params, params: {event_id: event.id})
    end
  end

  def self.new_task(user, task, team = false)
    if team
      message = 'new_team_task'
      path = Rails.application.routes.url_helpers.my_teams_tasks_path(q: "task,#{task.id}")
      sms_message = I18n.translate("notifications_sms.new_unassigned_team_task", url: Rails.application.routes.url_helpers.my_teams_tasks_url(new_at: Time.now.to_i))
      email_subject = I18n.translate("notification_types.new_unassigned_team_task")
      email_message = I18n.translate("notifications_email.new_unassigned_team_task", url: Rails.application.routes.url_helpers.my_teams_tasks_url(new_at: Time.now.to_i))
    else
      message = 'new_task'
      path = Rails.application.routes.url_helpers.mine_tasks_path(q: "task,#{task.id}")
      sms_message = I18n.translate("notifications_sms.new_task_assignment", url: Rails.application.routes.url_helpers.mine_tasks_url(new_at: Time.now.to_i))
      email_subject = I18n.translate("notification_types.new_task_assignment")
      email_message = I18n.translate("notifications_email.new_task_assignment", url: Rails.application.routes.url_helpers.mine_tasks_url(new_at: Time.now.to_i))
    end

    if user.notifications.where(path: path).count == 0
      if (!team && user.allow_notification?('new_task_assignment_sms')) ||
         (team && user.allow_notification?('new_unassigned_team_task_sms'))
        Resque.enqueue(SendSmsWorker, user.phone_number, sms_message)
      end
      if (!team && user.allow_notification?('new_task_assignment_email')) ||
         (team && user.allow_notification?('new_unassigned_team_task_email'))
        UserMailer.notification(user.id, email_subject, email_message).deliver
      end
      notification = user.notifications.create(path: path, level: 'grey', message: message, message_params: {task: task.title}, icon: 'task', params: {task_id: task.id})
    end
  end

  def self.grouped_notifications_counts(notifications)
    Hash[connection.select_rows(notifications.select('message, count(notifications.id)').group('notifications.message').to_sql)]
  end

  # Sends late/due events notifications to users that have it enabled
  def self.send_late_event_sms_notifications
    CompanyUser.includes(:company).active.with_confirmed_phone_number.with_timezone.
    with_notifications(['event_recap_late_sms', 'event_recap_due_sms']).find_each do |user|
      date_field = (user.company.timezone_support? ? :local_end_at : :end_at)
      due_date = user.company.due_event_end_date.utc
      late_date = user.company.late_event_end_date.utc

      events_scope = Event.active.unsent.accessible_by_user(user).with_user_in_team(user)
      late_count = user.allow_notification?('event_recap_late_sms') ? events_scope.where("#{date_field} < ?", late_date).count : 0
      due_count = user.allow_notification?('event_recap_due_sms') ? events_scope.where("#{date_field} < :due AND #{date_field} > :late", due: due_date, late: late_date).count : 0
      message = if late_count > 0 && due_count > 0
        I18n.translate('notifications_sms.event_recap_late_and_due',
          late_count: late_count,
          due_count: due_count
        )
      elsif late_count > 0
        I18n.translate('notifications_sms.event_recap_late', count: late_count)
      elsif due_count > 0
        I18n.translate('notifications_sms.event_recap_due', count: due_count)
      end
      Resque.enqueue SendSmsWorker, user.phone_number, message if message
    end
  end
end
