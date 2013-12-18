# == Schema Information
#
# Table name: companies
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  timezone_support :boolean
#

require 'spec_helper'

describe Company do
  it { should have_many(:company_users) }
  it { should have_many(:teams) }
  it { should have_many(:campaigns) }
  it { should have_many(:roles) }

  it { should validate_presence_of(:name) }

end
