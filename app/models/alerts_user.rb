# == Schema Information
#
# Table name: alerts_users
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  name            :string(255)
#  version         :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class AlertsUser < ActiveRecord::Base
  belongs_to :company_user
end
