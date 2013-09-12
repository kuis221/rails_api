class Notification < ActiveRecord::Base
  belongs_to :company_user
  attr_accessible :icon, :level, :message, :path


  def self.new_campaing(user, campaing)
    path = Rails.application.routes.url_helpers.campaign_path(campaing)
    if user.notifications.where(path: path).count == 0
      notification = user.notifications.create(path: path, level: 'info', message: 'new_campaign', icon: 'campaign')
    end
  end
end
