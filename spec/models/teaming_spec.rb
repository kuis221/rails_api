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

describe Teaming do
  it { should belong_to(:team) }
  it { should belong_to(:teamable) }
  it { should validate_presence_of(:teamable_id) }
  it { should validate_presence_of(:teamable_type) }

  describe "new event notification" do
    let(:event) { FactoryGirl.create(:event) }
    let(:user) { FactoryGirl.create(:company_user) }

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
end
