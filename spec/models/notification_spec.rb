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

  it { should allow_mass_assignment_of(:icon) }
  it { should allow_mass_assignment_of(:level) }
  it { should allow_mass_assignment_of(:message) }
  it { should allow_mass_assignment_of(:path) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:company_user_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }
end
