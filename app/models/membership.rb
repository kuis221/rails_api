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

  after_create :create_notifications
  after_create :update_tasks
  after_create :clear_cache

  after_destroy :delete_notifications
  after_destroy :update_tasks
  after_destroy :clear_cache
  after_destroy :delete_goals

  validates :memberable_id, presence: true
  validates :memberable_type, presence: true

  validate :same_company

  belongs_to :parent, polymorphic: true

  private
    def create_notifications
      if memberable_type == 'Campaign' && company_user.role.has_permission?(:read, Campaign)
        Notification.new_campaign(company_user, memberable)
      elsif memberable_type == 'Event' && company_user.allowed_to_access_place?(memberable.place)
        Notification.new_event(company_user, memberable)
      end
    end

    def delete_notifications
      if memberable_type == 'Campaign'
        company_user.notifications.where(path: Rails.application.routes.url_helpers.campaign_path(memberable)).destroy_all
      elsif memberable_type == 'Event'
        company_user.notifications.where(path: Rails.application.routes.url_helpers.event_path(memberable)).destroy_all
        company_user.notifications.where("params->'task_id' in (?)", memberable.task_ids.map{|n| n.to_s}).destroy_all
      end
    end

    def delete_goals
      memberable.remove_child_goals_for(self.company_user) if memberable.respond_to?(:remove_child_goals_for)
    end

    def update_tasks
      if memberable_type == 'Event'
        Sunspot.index(memberable.tasks)
        Sunspot.index(memberable)
      end
    end

    def clear_cache
      if memberable.is_a?(Area)
        Rails.cache.delete("user_accessible_locations_#{company_user_id}")
        Rails.cache.delete("user_accessible_places_#{company_user_id}")
      elsif memberable.is_a?(Campaign) || memberable.is_a?(Brand) || memberable.is_a?(BrandPortfolio)
        Rails.cache.delete("user_accessible_campaigns_#{company_user_id}")
      end
      true
    end

    # Validates that the user and the memberable are from the same company
    def same_company
      if company_user.company_id != memberable.company_id
        errors.add(:memberable_id, :invalid)
      end
    end
end
