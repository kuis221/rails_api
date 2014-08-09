require 'spec_helper'

describe EventNotifierWorker do
  describe "#perform" do
    let(:company) { FactoryGirl.create(:company) }
    let(:place) { FactoryGirl.create(:place) }
    let(:campaign) { FactoryGirl.create(:campaign, company: company) }
    let(:event){ FactoryGirl.create(:event, campaign: campaign, place: place) }
    let(:non_admin_role) { FactoryGirl.create(:non_admin_role, company: company) }

    it "should create notifications for each user in the event's campaign" do
      team = FactoryGirl.create(:team, company: company)
      user1 = FactoryGirl.create(:company_user, role: non_admin_role, company: company)
      user1.places << place
      campaign.users << user1

      user2 = FactoryGirl.create(:company_user, role: non_admin_role, company: company)
      user2.places << place
      team.users << user2

      campaign.teams << team

      # Admin user
      admin_user = FactoryGirl.create(:company_user, company: company)

      # Non Admin user without access to the campaign
      FactoryGirl.create(:company_user, role: non_admin_role, company: company)

      expect{
        EventNotifierWorker.perform(event.id)
      }.to change(Notification, :count).by(3)

      expect(Notification.where(message: :new_event).map(&:company_user_id)).to match_array [
        admin_user.id, user1.id, user2.id
      ]
    end

    it "should not create notifications event doesn't have a place" do
      user = FactoryGirl.create(:company_user, role: non_admin_role, company: company)
      user.places << place
      campaign.users << user
      event = FactoryGirl.create(:event, campaign: campaign)

      expect{
        EventNotifierWorker.perform(event.id)
      }.not_to change(Notification, :count)
    end

  end
end