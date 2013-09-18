# == Schema Information
#
# Table name: memberships
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  memberable_id   :integer
#  memberable_type :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe Membership do
  it { should belong_to(:company_user) }
  it { should belong_to(:memberable) }

  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:company_user_id) }
  it { should_not allow_mass_assignment_of(:memberable_id) }
  it { should_not allow_mass_assignment_of(:memberable_type) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  describe "new campaign notification" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:user) { FactoryGirl.create(:company_user) }

    it "should generate a new notification" do
      expect {
        campaign.users << user
      }.to change(Notification, :count).by(1)
    end

    it "should generate a new notification" do
      campaign.users << user
      expect {
        campaign.users.destroy(user)
      }.to change(Notification, :count).by(-1)
    end
  end
end
