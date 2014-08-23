# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  commentable_id   :integer
#  commentable_type :string(255)
#  content          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Comment < ActiveRecord::Base
  track_who_does_it

  acts_as_readable :on => :created_at

  belongs_to :commentable, :polymorphic => true
  belongs_to :user, :foreign_key => "created_by_id"

  delegate :full_name, to: :user, prefix: true, allow_nil: true

  delegate :company_id, to: :commentable

  validates :content, presence: true
  validates :commentable_id, presence: true, numericality: true
  validates :commentable_type, presence: true

  scope :for_places, lambda{|places, company| joins('INNER JOIN events e ON e.id = commentable_id and commentable_type=\'Event\'').where(['e.place_id in (?) and e.company_id in (?)', places, company]) }

  scope :for_tasks_assigned_to, lambda{|users| joins('INNER JOIN tasks t ON t.id = commentable_id and commentable_type=\'Task\'').where(['t.company_user_id in (?)', users]) }

  scope :for_tasks_where_user_in_team, lambda{|users| joins('INNER JOIN tasks t ON t.id = commentable_id and commentable_type=\'Task\'').where("t.event_id in (#{Event.select('events.id').with_user_in_team(users).to_sql})") }

  scope :not_from, lambda{|user| where(['comments.created_by_id<>?', user]) }

  scope :for_user_accessible_events, ->(company_user) { joins('INNER JOIN events ec ON ec.id = commentable_id and commentable_type=\'Event\' and ec.id in ('+Event.select('events.id').where(company_id: company_user.company_id).accessible_by_user(company_user).to_sql+')') }

  after_create :reindex_event

  after_save :send_notifications

  private

    def reindex_event
      if commentable.is_a?(Event)
        Sunspot.index commentable
      end
    end

    def send_notifications
      if commentable_type == 'Task'
        #Case when Task has an assigned user
        if commentable.company_user.present?
          if commentable.company_user.allow_notification?('new_comment_sms')
            sms_message = I18n.translate("notifications_sms.new_comment", url: Rails.application.routes.url_helpers.mine_tasks_url(q: "task,#{commentable_id}", anchor: "comments-#{commentable_id}"))
            Resque.enqueue(SendSmsWorker, commentable.company_user.phone_number, sms_message)
          end
          if commentable.company_user.allow_notification?('new_comment_email')
            email_message = I18n.translate("notifications_email.new_comment", url: Rails.application.routes.url_helpers.mine_tasks_url(q: "task,#{commentable_id}", anchor: "comments-#{commentable_id}"))
            UserMailer.notification(commentable.company_user.id, I18n.translate("notification_types.new_comment"), email_message).deliver
          end
        else #Case when Task has not an assigned user, send messages to all event's team
          sms_message = I18n.translate("notifications_sms.new_team_comment", url: Rails.application.routes.url_helpers.mine_tasks_url(q: "task,#{commentable_id}", anchor: "comments-#{commentable_id}"))
          commentable.event.all_users.each do |user|
            if user.allow_notification?('new_team_comment_sms')
              Resque.enqueue(SendSmsWorker, user.phone_number, sms_message)
            end
            if user.allow_notification?('new_team_comment_email')
              email_message = I18n.translate("notifications_email.new_team_comment", url: Rails.application.routes.url_helpers.mine_tasks_url(q: "task,#{commentable_id}", anchor: "comments-#{commentable_id}"))
              UserMailer.notification(user.id, I18n.translate("notification_types.new_team_comment"), email_message).deliver
            end
          end
        end
      end
    end
end
