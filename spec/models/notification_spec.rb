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

require 'spec_helper'

describe Notification do
  it { should belong_to(:company_user) }
end
