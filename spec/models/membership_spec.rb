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

require 'rails_helper'

describe Membership, type: :model do
  it { is_expected.to belong_to(:company_user) }
  it { is_expected.to belong_to(:memberable) }

  describe 'new campaign notification' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company) }
    let(:user) { create(:company_user, company: company) }

    it 'should generate a new notification' do
      expect do
        campaign.users << user
      end.to change(Notification, :count).by(1)
    end

    it 'should remove a notification' do
      campaign.users << user
      expect do
        campaign.users.destroy(user)
      end.to change(Notification, :count).by(-1)
    end
  end

  describe '#delete_goals after_destroy callback' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company) }
    let(:user) { create(:company_user, company: company) }
    it 'should remove the goals for the user' do
      campaign.users << user
      goal = create(:goal, parent: campaign, goalable: user, value: 100, kpi: create(:kpi))
      expect do
        expect do
          campaign.users.destroy(user)
        end.to change(Membership, :count).by(-1)
      end.to change(Goal, :count).by(-1)
    end
  end
end
