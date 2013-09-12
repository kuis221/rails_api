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
#

class Membership < ActiveRecord::Base
  belongs_to :company_user
  belongs_to :memberable, polymorphic: true
  # attr_accessible :title, :body

  after_create :create_notifications
  after_destroy :delete_notifications

  private
    def create_notifications
      if memberable_type == 'Campaign'
        Notification.new_campaing(company_user, memberable)
      end
    end

    def delete_notifications
      if memberable_type == 'Campaign'
        company_user.notifications.where(path: Rails.application.routes.url_helpers.campaign_path(memberable)).delete_all
      end
    end
end
