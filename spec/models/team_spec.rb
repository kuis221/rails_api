# == Schema Information
#
# Table name: teams
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active        :boolean          default(TRUE)
#  company_id    :integer
#

require 'spec_helper'

describe Team, :type => :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to have_many(:memberships) }
  it { is_expected.to have_many(:users).through(:memberships) }

  it { is_expected.to validate_presence_of(:name) }

  describe "#activate" do
    let(:team) { FactoryGirl.build(:team, active: false) }

    it "should return the active value as true" do
      team.activate!
      team.reload
      expect(team.active).to be_truthy
    end
  end

  describe "#deactivate" do
    let(:team) { FactoryGirl.build(:team, active: false) }

    it "should return the active value as false" do
      team.deactivate!
      team.reload
      expect(team.active).to be_falsey
    end
  end

end
