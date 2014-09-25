# == Schema Information
#
# Table name: teamings
#
#  id            :integer          not null, primary key
#  team_id       :integer
#  teamable_id   :integer
#  teamable_type :string(255)
#

class Teaming < ActiveRecord::Base
  belongs_to :team
  belongs_to :teamable, polymorphic: true

  validates :teamable, presence: true

  after_create :create_notifications
  after_create :update_tasks

  after_destroy :delete_notifications
  after_destroy :update_tasks
  after_destroy :delete_goals

  private

  def create_notifications
    if teamable_type == 'Event'
      if teamable.company.event_alerts_policy == Notification::EVENT_ALERT_POLICY_TEAM
        team.users.each do |user|
          if user.allowed_to_access_place?(teamable.place)
            Notification.new_event(user, teamable, team)
          end
        end
      end
    end
  end

  def delete_goals
    teamable.remove_child_goals_for(team) if teamable.respond_to?(:remove_child_goals_for)
  end

  def delete_notifications
    if teamable_type == 'Event'
      team.users.each do |user|
        user.notifications.where(path: Rails.application.routes.url_helpers.event_path(teamable), message: 'new_team_event').destroy_all
        # user.notifications.where("params->'task_id' in (?)", teamable.task_ids.map{|n| n.to_s}).destroy_all
      end
    end
  end

  def update_tasks
    if teamable_type == 'Event'
      Sunspot.index(teamable.tasks)
    end
  end
end
