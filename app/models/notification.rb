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
#

class Notification < ActiveRecord::Base
  belongs_to :company_user
  attr_accessible :icon, :level, :message, :message_params, :path

  serialize :message_params


  def self.new_campaign(user, campaign)
    path = Rails.application.routes.url_helpers.campaign_path(campaign)
    if user.notifications.where(path: path).count == 0
      notification = user.notifications.create(path: path, level: 'grey', message: 'new_campaign', icon: 'campaign')
    end
  end

  def self.new_event(user, event)
    path = Rails.application.routes.url_helpers.event_path(event)
    if user.notifications.where(path: path).count == 0
      notification = user.notifications.create(path: path, level: 'grey', message: 'new_event', icon: 'event')
    end
  end

  def self.new_task(user, task, team = false)
    if team
      path = Rails.application.routes.url_helpers.my_teams_tasks_path(q: "task,#{task.id}")
      message = 'new_team_task'
    else
      path = Rails.application.routes.url_helpers.mine_tasks_path(q: "task,#{task.id}")
      message = 'new_task'
    end

    if user.notifications.where(path: path).count == 0
      notification = user.notifications.create(path: path, level: 'grey', message: message, message_params: {task: task.title}, icon: 'task')
    end
  end
end
