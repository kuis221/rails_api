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
#

class Notification < ActiveRecord::Base
  belongs_to :company_user
  attr_accessible :icon, :level, :message, :path


  def self.new_campaign(user, campaign)
    path = Rails.application.routes.url_helpers.campaign_path(campaign)
    if user.notifications.where(path: path).count == 0
      notification = user.notifications.create(path: path, level: 'grey', message: 'new_campaign', icon: 'campaign')
    end
  end
end
