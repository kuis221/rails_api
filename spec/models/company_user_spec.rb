# == Schema Information
#
# Table name: company_users
#
#  id         :integer          not null, primary key
#  company_id :integer
#  user_id    :integer
#  role_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  active     :boolean          default(TRUE)
#

require 'spec_helper'

describe CompanyUser do
  it { should belong_to(:user) }
  it { should belong_to(:company) }
  it { should belong_to(:role) }

  it { should validate_presence_of(:role_id) }
  it { should validate_numericality_of(:role_id) }

  it { should validate_presence_of(:company_id) }
  it { should validate_numericality_of(:company_id) }

  it { should allow_mass_assignment_of(:role_id) }
  it { should_not allow_mass_assignment_of(:company_id) }
  it { should_not allow_mass_assignment_of(:user_id) }
end
