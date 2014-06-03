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

  validates :teamable_id, presence: true
  validates :teamable_type, presence: true

  after_create :create_notifications
  after_create :update_tasks

  after_destroy :delete_notifications
  after_destroy :update_tasks

  private
    def create_notifications
      if teamable_type == 'Event'
        team.users.each do |user|
          if user.allowed_to_access_place?(teamable.place)
            Notification.new_event(user, teamable, team)
          end
        end
      end
    end

    def delete_notifications
      if teamable_type == 'Event'
        team.users.each do |user|
          user.notifications.where(path: Rails.application.routes.url_helpers.event_path(teamable), message: 'new_team_event').delete_all
          #user.notifications.where("params->'task_id' in (?)", teamable.task_ids.map{|n| n.to_s}).delete_all
        end
      end
    end

    def update_tasks
      if teamable_type == 'Event'
        Sunspot.index(teamable.tasks)
      end
    end
end
