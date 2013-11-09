# == Schema Information
#
# Table name: memberships
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  memberable_id   :integer
#  memberable_type :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_id       :integer
#  parent_type     :string(255)
#

class Membership < ActiveRecord::Base
  belongs_to :company_user
  belongs_to :memberable, polymorphic: true
  # attr_accessible :title, :body

  after_create :create_notifications
  after_create :update_tasks

  after_destroy :delete_notifications
  after_destroy :update_tasks

  validates :memberable_id, presence: true
  validates :memberable_type, presence: true

  belongs_to :parent, polymorphic: true

  private
    def create_notifications
      if memberable_type == 'Campaign'
        Notification.new_campaign(company_user, memberable)
      elsif memberable_type == 'Event'
        Notification.new_event(company_user, memberable)
      end
    end

    def delete_notifications
      if memberable_type == 'Campaign'
        company_user.notifications.where(path: Rails.application.routes.url_helpers.campaign_path(memberable)).delete_all
      elsif memberable_type == 'Event'
        company_user.notifications.where(path: Rails.application.routes.url_helpers.event_path(memberable)).delete_all
      end
    end

    def update_tasks
      if memberable_type == 'Event'
        Sunspot.index(memberable.tasks)
        Sunspot.index(memberable)
      end
    end
end
