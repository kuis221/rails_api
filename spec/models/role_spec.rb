# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  permissions :text
#  company_id  :integer
#

require 'spec_helper'

describe Role do
  it { should belong_to(:company) }

  it { should validate_presence_of(:name) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:permissions) }
  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  it { should have_many(:users) }
end
