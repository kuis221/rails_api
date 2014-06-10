# == Schema Information
#
# Table name: company_users
#
#  id               :integer          not null, primary key
#  company_id       :integer
#  user_id          :integer
#  role_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  active           :boolean          default(TRUE)
#  last_activity_at :datetime
#

require 'spec_helper'

describe CompanyUser do
  it { should belong_to(:user) }
  it { should belong_to(:company) }
  it { should belong_to(:role) }
  it { should have_many(:tasks) }
  it { should have_many(:memberships) }
  it { should have_many(:teams).through(:memberships) }
  it { should have_many(:campaigns).through(:memberships) }
  it { should have_many(:events).through(:memberships) }

  it { should validate_presence_of(:role_id) }
  it { should validate_numericality_of(:role_id) }

  it { should validate_presence_of(:company_id) }
  it { should validate_numericality_of(:company_id) }


  describe "#deactivate" do
    it "should deactivate the status of the user on the current company" do
      user = FactoryGirl.create(:company_user, active: true)
      user.deactivate!
      user.reload.active.should be_false
    end

    it "should activate the status of the user on the current company" do
      user = FactoryGirl.create(:company_user, active: false)
      user.activate!
      user.reload.active.should be_true
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
      CompanyUser.by_teams(team).all.should =~ users
      CompanyUser.by_teams(other_team).all.should =~ other_users
      CompanyUser.by_teams([team, other_team]).all.should =~ users + other_users
    end
  end

  describe "#by_events scope" do
    it "should return users that assigned to the specific events" do
      users = [
        FactoryGirl.create(:company_user),
        FactoryGirl.create(:company_user)
      ]
      other_users = [
        FactoryGirl.create(:company_user)
      ]
      event = FactoryGirl.create(:event)
      other_event = FactoryGirl.create(:event)
      users.each{|u| event.users << u}
      other_users.each{|u| other_event.users << u}
      CompanyUser.by_events(event).all.should =~ users
      CompanyUser.by_events(other_event).all.should =~ other_users
      CompanyUser.by_events([event, other_event]).all.should =~ users + other_users
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
        user.accessible_campaign_ids.should == [campaign.id]
      end

      it "should return the ids of campaigns of a brand assigend to the user" do
        campaign.brands << brand
        user.brands << brand
        user.accessible_campaign_ids.should == [campaign.id]
      end

      it "should return the ids of campaigns of a brand assigend to the user" do
        campaign.brands << brand
        user.brands << brand
        user.accessible_campaign_ids.should == [campaign.id]
      end

      it "should return the ids of campaigns of a brand portfolio assigned to the user" do
        campaign.brand_portfolios << portfolio
        user.brand_portfolios << portfolio
        user.accessible_campaign_ids.should == [campaign.id]
      end
    end
    describe "as an admin user" do
      let(:user)      { FactoryGirl.create(:company_user, company: FactoryGirl.create(:company)) }

      it "should return the ids of campaigns assigend to the user" do
        campaigns = FactoryGirl.create_list(:campaign, 3, company: user.company)
        other_campaigns = FactoryGirl.create_list(:campaign, 2, company_id: user.company.id+1)
        expect(user.accessible_campaign_ids).to match_array campaigns.map(&:id)
      end
    end
  end

  describe "#allowed_to_access_place?" do
    let(:user)      { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }
    let(:campaign)  { FactoryGirl.create(:campaign, company_id: 1) }
    let(:place)  { FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles') }

    it "should return false if the user doesn't places associated" do
      expect(user.allowed_to_access_place?(place)).to be_false
    end

    it "should return true if the user has access to the city" do
      user.places << FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
      expect(user.allowed_to_access_place?(place)).to be_true
    end

    it "should return true if the user has access to an area that includes the place's city" do
      city = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
      area = FactoryGirl.create(:area, company_id: 1)
      area.places << city
      user.areas << area
      expect(user.allowed_to_access_place?(place)).to be_true
    end

    it "should work with places that are not yet saved" do
      place = FactoryGirl.build(:place, country: 'US', state: 'California', city: 'Los Angeles')
      city = FactoryGirl.create(:place, country: 'US', state: 'California', city: 'Los Angeles', types: ['locality'])
      area = FactoryGirl.create(:area, company_id: 1)
      area.places << city
      user.areas << area
      expect(user.allowed_to_access_place?(place)).to be_true
    end
  end

  describe "#accessible_places" do
    let(:user)      { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }
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
    let(:user)      { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }
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

  describe "#notification_setting_permission?" do
    let(:user) { FactoryGirl.create(:company_user, company_id: 1, role: FactoryGirl.create(:role, is_admin: false)) }

    it "should return false if the user hasn't the correct permissions" do
      expect(user.notification_setting_permission?('new_campaign')).to be_false
    end

    it "should return false if the user hasn the correct permissions" do
      user.role.permissions.create({action: :read, subject_class: 'Campaign'}, without_protection: true)
      expect(user.notification_setting_permission?('new_campaign')).to be_true
    end
  end
end
