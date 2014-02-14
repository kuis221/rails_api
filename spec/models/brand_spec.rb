# == Schema Information
#
# Table name: brands
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe Brand do

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }

  it { should have_and_belong_to_many(:campaigns) }
  it { should have_many(:brand_portfolios_brands) }
  it { should have_many(:brand_portfolios) }
  it { should have_many(:marques) }
end
