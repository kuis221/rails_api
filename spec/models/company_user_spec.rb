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
end
