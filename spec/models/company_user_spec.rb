# == Schema Information
#
# Table name: company_users
#
#  id                     :integer          not null, primary key
#  company_id             :integer
#  user_id                :integer
#  role_id                :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  active                 :boolean          default(TRUE)
#  last_activity_at       :datetime
#  notifications_settings :string(255)      default([]), is an Array
#

require 'rails_helper'

describe CompanyUser, :type => :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:role) }
  it { is_expected.to have_many(:tasks) }
  it { is_expected.to have_many(:memberships) }
  it { is_expected.to have_many(:teams).through(:memberships) }
  it { is_expected.to have_many(:campaigns).through(:memberships) }
  it { is_expected.to have_many(:events).through(:memberships) }

  it { is_expected.to validate_presence_of(:role_id) }
  it { is_expected.to validate_numericality_of(:role_id) }

  it { is_expected.to validate_presence_of(:company_id) }
  it { is_expected.to validate_numericality_of(:company_id) }


  describe "#deactivate" do
    it "should deactivate the status of the user on the current company" do
      user = FactoryGirl.create(:company_user, active: true)
      user.deactivate!
      expect(user.reload.active).to be_falsey
    end

    it "should activate the status of the user on the current company" do
      user = FactoryGirl.create(:company_user, active: false)
      user.activate!
      expect(user.reload.active).to be_truthy
    end
  end

  describe "#by_teams scope" do
    it "should return users that belongs to the give teams" do
      users = [
        FactoryGirl.create(:company_user),
        FactoryGirl.create(:company_user)
      ]
      other_users = [
        FactoryGirl.create(:company_user)
      ]
      team = FactoryGirl.create(:team)
      other_team = FactoryGirl.create(:team)
      users.each{|u| team.users << u}
      other_users.each{|u| other_team.users << u}
      expect(CompanyUser.by_teams(team).all).to match_array(users)
      expect(CompanyUser.by_teams(other_team).all).to match_array(other_users)
      expect(CompanyUser.by_teams([team, other_team]).all).to match_array(users + other_users)
    end
  end

  describe "#by_events scope" do
    it "should return users that assigned to the specific events" do
      event = FactoryGirl.create(:event)
      users = [
        FactoryGirl.create(:company_user, company: event.company),
        FactoryGirl.create(:company_user, company: event.company)
      ]
      other_users = [
        FactoryGirl.create(:company_user, company: event.company)
      ]
      other_event = FactoryGirl.create(:event, company: event.company)
      users.each{|u| event.users << u}
      other_users.each{|u| other_event.users << u}
      expect(CompanyUser.by_events(event).all).to match_array(users)
      expect(CompanyUser.by_events(other_event).all).to match_array(other_users)
      expect(CompanyUser.by_events([event, other_event]).all).to match_array(users + other_users)
    end
  end

  describe "#accessible_campaign_ids" do
    describe "as a non admin user" do
      let(:user)      { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }
      let(:brand)     { FactoryGirl.create(:brand) }
      let(:campaign)  { FactoryGirl.create(:campaign, company_id: 1) }
      let(:portfolio) { FactoryGirl.create(:brand_portfolio) }

      it "should return the ids of campaigns assigend to the user" do
        user.campaigns << campaign
        expect(user.accessible_campaign_ids).to eq([campaign.id])
      end

      it "should return the ids of campaigns of a brand assigend to the user" do
        campaign.brands << brand
        user.brands << brand
        expect(user.accessible_campaign_ids).to eq([campaign.id])
      end

      it "should return the ids of campaigns of a brand assigend to the user" do
        campaign.brands << brand
        user.brands << brand
        expect(user.accessible_campaign_ids).to eq([campaign.id])
      end

      it "should return the ids of campaigns of a brand portfolio assigned to the user" do
        campaign.brand_portfolios << portfolio
        user.brand_portfolios << portfolio
        expect(user.accessible_campaign_ids).to eq([campaign.id])
      end
    end
    describe "as an admin user" do
      let(:user)      { FactoryGirl.create(:company_user, company: FactoryGirl.create(:company)) }

      it "should return the ids of campaigns assigend to the user" do
        campaigns = FactoryGirl.create_list(:campaign, 3, company: user.company)
        FactoryGirl.create_list(:campaign, 2, company_id: user.company.id+1)
        expect(user.accessible_campaign_ids).to match_array campaigns.map(&:id)
      end
    end
  end

  describe "#allowed_to_access_place?" do
    let(:user)      { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }
    let(:campaign)  { FactoryGirl.create(:campaign, company_id: 1) }
    let(:place)  { FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles') }

    it "should return false if the user doesn't places associated" do
      expect(user.allowed_to_access_place?(place)).to be_falsey
    end

    it "should return true if the user has access to the city" do
      user.places << FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
      expect(user.allowed_to_access_place?(place)).to be_truthy
    end

    it "should return true if the user has access to an area that includes the place's city" do
      city = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
      area = FactoryGirl.create(:area, company_id: 1)
      area.places << city
      user.areas << area
      expect(user.allowed_to_access_place?(place)).to be_truthy
    end

    it "should work with places that are not yet saved" do
      place = FactoryGirl.build(:place, country: 'US', state: 'California', city: 'Los Angeles')
      city = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
      area = FactoryGirl.create(:area, company_id: 1)
      area.places << city
      user.areas << area
      expect(user.allowed_to_access_place?(place)).to be_truthy
    end
  end

  describe "#accessible_places" do
    let(:user) { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }
    it "should return the id of the places assocaited to the user" do
      FactoryGirl.create(:place)
      place = FactoryGirl.create(:place)
      FactoryGirl.create(:place)
      user.places << place
      expect(user.accessible_places).to include(place.id)
    end
    it "should return the id of the places of areas associated to the user" do
      FactoryGirl.create(:place)
      place = FactoryGirl.create(:place)
      FactoryGirl.create(:place)
      FactoryGirl.create(:area, company_id: user.company_id)
      area = FactoryGirl.create(:area, company_id: user.company_id)
      area.places << place
      user.areas << area
      expect(user.accessible_places).to include(place.id)
    end
  end

  describe "#accessible_locations" do
    let(:user) { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }
     it "should return the location id of the city" do
        city = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
        user.places << city
        expect(user.accessible_locations).to include(city.location_id)
     end
     it "should return the location id of the city if belongs to an user's area" do
        city = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
        area = FactoryGirl.create(:area, company_id: user.company_id)
        area.places << city
        user.areas << area
        expect(user.accessible_locations).to include(city.location_id)
     end
     it "should not include the location id of the venues" do
        bar = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['establishment', 'bar'])
        user.places << bar
        expect(user.accessible_locations).to be_empty
     end
  end

  describe "#allow_notification?" do
    let(:user) { FactoryGirl.create(:company_user, company_id: 1,
      role: FactoryGirl.create(:role, is_admin: false)) }

    it "should return false if the user is not allowed to receive a notification" do
      expect(user.allow_notification?('new_campaign_sms')).to be_falsey
    end

    it "should return true if the user is allowed to receive a notification" do
      user.update_attributes(notifications_settings: ['new_campaign_sms'],
        user_attributes: {phone_number_verified: true} )
      expect(user.allow_notification?('new_campaign_sms')).to be_truthy
    end

    describe "user without phone number" do
      it "should return true if the user is allowed to receive a notification" do
        user.user.phone_number = nil
        user.update_attributes({notifications_settings: ['new_campaign_app', 'new_campaign_sms']})
        expect(user.allow_notification?('new_campaign_app')).to be_truthy
        expect(user.allow_notification?('new_campaign_sms')).to be_falsey
      end
    end
  end

  describe "#notification_setting_permission?" do
    let(:user) { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }

    it "should return false if the user hasn't the correct permissions" do
      expect(user.notification_setting_permission?('new_campaign')).to be_falsey
    end

    it "should return true if the user has the correct permissions" do
      user.role.permissions.create({action: :read, subject_class: 'Campaign'})
      expect(user.notification_setting_permission?('new_campaign')).to be_truthy
    end
  end


  describe "#with_notifications" do
    it "should return empty if no users have the any of the notifications enabled" do
      FactoryGirl.create(:company_user)
      expect(CompanyUser.with_notifications(['some_notification'])).to be_empty
    end

    it "should return all users with any of the notifications enabled" do
      user1 = FactoryGirl.create(:company_user,
        notifications_settings: ['notification2', 'notification1'])

      user2 = FactoryGirl.create(:company_user,
        notifications_settings: ['notification3', 'notification4', 'notification1'])

      expect(CompanyUser.with_notifications(['notification2'])).to match_array [user1]

      expect(CompanyUser.with_notifications(['notification1'])).to match_array [user1, user2]
    end
  end

  describe "#campaigns_changed" do
    let(:company) { FactoryGirl.create(:company) }
    let(:company_user) { FactoryGirl.create(:company_user, company: company) }
    let(:campaign) { FactoryGirl.create(:campaign, company: company) }
    let(:brand) { FactoryGirl.create(:brand, company: company) }
    let(:brand_portfolio) { FactoryGirl.create(:brand_portfolio, company: company) }

    it "should clear cache after adding campaigns to user" do
      expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_notifications_#{company_user.id}").at_least(:once)
      company_user.campaigns << campaign
    end

    it "should clear cache after adding brands to user" do
      expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_notifications_#{company_user.id}").at_least(:once)
      company_user.brands << brand
    end

    it "should clear cache after adding brand portfolios to user" do
      expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_notifications_#{company_user.id}").at_least(:once)
      company_user.brand_portfolios << brand_portfolio
    end

    it "should clear cache after adding campaigns to user" do
      company_user.campaigns << campaign
      expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_notifications_#{company_user.id}").at_least(:once)
      company_user.campaigns.destroy campaign
    end

    it "should clear cache after adding brands to user" do
      company_user.brands << brand
      expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_notifications_#{company_user.id}").at_least(:once)
      company_user.brands.destroy brand
    end

    it "should clear cache after adding brand portfolios to user" do
      company_user.brand_portfolios << brand_portfolio
      expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_notifications_#{company_user.id}").at_least(:once)
      company_user.brand_portfolios.destroy brand_portfolio
    end
  end

  describe "default notifications settings" do
    it "should assign all notifications settings on creation " do
      user = FactoryGirl.create(:company_user, notifications_settings: nil)
      expect(user.notifications_settings).not_to be_empty
      expect(user.notifications_settings.length).to eql CompanyUser::NOTIFICATION_SETTINGS_TYPES.length
      expect(user.notifications_settings).to include('event_recap_due_app')
    end
  end
end
