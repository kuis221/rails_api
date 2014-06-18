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
  attr_accessible :icon, :level, :message, :message_params, :extra_params, :params, :path

  serialize :message_params
  serialize :extra_params
  serialize :params, ActiveRecord::Coders::Hstore

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
      notification = user.notifications.create(path: path, level: 'grey', message: message, icon: 'event', message_params: message_params, params: {event_id: event.id})
    end
  end

  def self.new_task(user, task, team = false)
    if team
      path = Rails.application.routes.url_helpers.my_teams_tasks_path(q: "task,#{task.id}")
      sms_message = I18n.translate("notifications_sms.new_unassigned_team_task", url: Rails.application.routes.url_helpers.my_teams_tasks_url(new_at: Time.now.to_i))
      message = 'new_team_task'
    else
      path = Rails.application.routes.url_helpers.mine_tasks_path(q: "task,#{task.id}")
      sms_message = I18n.translate("notifications_sms.new_task_assignment", url: Rails.application.routes.url_helpers.mine_tasks_url(new_at: Time.now.to_i))
      message = 'new_task'
    end

    if user.notifications.where(path: path).count == 0
      if user.allow_notification?('new_task_assignment_sms') || user.allow_notification?('new_unassigned_team_task_sms')
        Resque.enqueue(SendSmsWorker, user.phone_number, sms_message)
      end
      notification = user.notifications.create(path: path, level: 'grey', message: message, message_params: {task: task.title}, icon: 'task', params: {task_id: task.id})
    end
  end

  def self.grouped_notifications_counts(notifications)
    Hash[connection.select_rows(notifications.select('message, count(notifications.id)').group('notifications.message').to_sql)]
  end
end
