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
#  parent_id       :integer
#  parent_type     :string(255)
#

require 'spec_helper'

describe Membership do
  it { should belong_to(:company_user) }
  it { should belong_to(:memberable) }

  describe "new campaign notification" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:user) { FactoryGirl.create(:company_user) }

    it "should generate a new notification" do
      expect {
        campaign.users << user
      }.to change(Notification, :count).by(1)
    end

    it "should remove a notification" do
      campaign.users << user
      expect {
        campaign.users.destroy(user)
      }.to change(Notification, :count).by(-1)
    end
  end

  describe "#delete_goals after_destroy callback" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:user) { FactoryGirl.create(:company_user) }
    it "should remove the goals for the user" do
      campaign.users << user
      goal = FactoryGirl.create(:goal, parent: campaign, goalable: user, value: 100, kpi: FactoryGirl.create(:kpi))
      expect {
        expect {
          campaign.users.destroy(user)
        }.to change(Membership, :count).by(-1)
      }.to change(Goal, :count).by(-1)
    end
  end
end
