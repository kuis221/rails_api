# == Schema Information
#
# Table name: teamings
#
#  id            :integer          not null, primary key
#  team_id       :integer
#  teamable_id   :integer
#  teamable_type :string(255)
#

require 'spec_helper'

describe Teaming, :type => :model do
  it { is_expected.to belong_to(:team) }
  it { is_expected.to belong_to(:teamable) }
  it { is_expected.to validate_presence_of(:teamable) }

  describe "new event notification" do
    let(:event) { FactoryGirl.create(:event) }
    let(:user) { FactoryGirl.create(:company_user, company: event.company) }

    it "should generate a new notification" do
      expect {
        event.users << user
      }.to change(Notification, :count).by(1)
    end

    it "should remove a notification" do
      event.users << user
      expect {
        event.users.destroy(user)
      }.to change(Notification, :count).by(-1)
    end
  end

  describe "new team event notification" do
    let(:event) { FactoryGirl.create(:event) }
    let(:user) { FactoryGirl.create(:company_user) }
    let(:team) { FactoryGirl.create(:team) }

    it "should generate a new notification" do
      team.users << user
      expect {
        event.teams << team
      }.to change(Notification, :count).by(1)
    end

    it "should remove a notification" do
      team.users << user
      event.teams << team
      expect {
        event.teams.destroy(team)
      }.to change(Notification, :count).by(-1)
    end
  end

  describe "#delete_goals after_destroy callback" do
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:team) { FactoryGirl.create(:team) }
    it "should remove the goals for the user" do
      campaign.teams << team
      goal = FactoryGirl.create(:goal, parent: campaign, goalable: team, value: 100, kpi: FactoryGirl.create(:kpi))
      expect {
        expect {
          campaign.teams.destroy(team)
        }.to change(Teaming, :count).by(-1)
      }.to change(Goal, :count).by(-1)
    end
  end
end
