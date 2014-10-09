# == Schema Information
#
# Table name: teamings
#
#  id            :integer          not null, primary key
#  team_id       :integer
#  teamable_id   :integer
#  teamable_type :string(255)
#

require 'rails_helper'

describe Teaming, type: :model do
  it { is_expected.to belong_to(:team) }
  it { is_expected.to belong_to(:teamable) }
  it { is_expected.to validate_presence_of(:teamable) }

  describe 'new event notification' do
    let(:event) { create(:event) }
    let(:user) { create(:company_user, company: event.company) }

    it 'should generate a new notification' do
      expect do
        event.users << user
      end.to change(Notification, :count).by(1)
    end

    it 'should remove a notification' do
      event.users << user
      expect do
        event.users.destroy(user)
      end.to change(Notification, :count).by(-1)
    end
  end

  describe 'new team event notification' do
    let(:event) { create(:event) }
    let(:user) { create(:company_user) }
    let(:team) { create(:team) }

    it 'should generate a new notification' do
      team.users << user
      expect do
        event.teams << team
      end.to change(Notification, :count).by(1)
    end

    it 'should remove a notification' do
      team.users << user
      event.teams << team
      expect do
        event.teams.destroy(team)
      end.to change(Notification, :count).by(-1)
    end
  end

  describe '#delete_goals after_destroy callback' do
    let(:campaign) { create(:campaign) }
    let(:team) { create(:team) }
    it 'should remove the goals for the user' do
      campaign.teams << team
      goal = create(:goal, parent: campaign, goalable: team, value: 100, kpi: create(:kpi))
      expect do
        expect do
          campaign.teams.destroy(team)
        end.to change(Teaming, :count).by(-1)
      end.to change(Goal, :count).by(-1)
    end
  end
end
