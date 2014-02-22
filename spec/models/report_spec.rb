# == Schema Information
#
# Table name: reports
#
#  id            :integer          not null, primary key
#  company_id    :integer
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  created_by_id :integer
#  updated_by_id :integer
#  rows          :text
#  columns       :text
#  values        :text
#  filters       :text
#

require 'spec_helper'

describe Report do
  it { should validate_presence_of(:name) }

  describe "#activate" do
    let(:report) { FactoryGirl.build(:report, active: false) }

    it "should return the active value as true" do
      report.activate!
      report.reload
      report.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:report) { FactoryGirl.build(:report, active: false) }

    it "should return the active value as false" do
      report.deactivate!
      report.reload
      report.active.should be_false
    end
  end


  describe "#fetch_page" do
    let(:company) { FactoryGirl.create(:company) }
    let(:campaign) { FactoryGirl.create(:campaign, company: company) }
    before do
      Kpi.create_global_kpis
    end
    it "returns nil if report has no rows, values and columns" do
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interacitons: 50})
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [],
        values:  [],
        columns: []
      )
      page = report.fetch_page
      expect(page).to be_nil
    end

    it "returns nil if report has rows but not values and columns" do
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interacitons: 50})
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}]
      )
      page = report.fetch_page
      expect(report.rows).to_not be_empty
      expect(page).to be_nil
    end

    it "returns a line for each different day where a event happens" do
      FactoryGirl.create(:event, start_date: '01/01/2014', end_date: '01/01/2014', campaign: campaign,
        results: {impressions: 100, interacitons: 50})
      FactoryGirl.create(:event, start_date: '01/12/2014', end_date: '01/12/2014', campaign: campaign,
        results: {impressions: 200, interacitons: 150})
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
          {"event_start_date"=>"2014/01/01", "kpi_#{Kpi.impressions.id}"=>"100.00"},
          {"event_start_date"=>"2014/01/12", "kpi_#{Kpi.impressions.id}"=>"200.00"}
      ]
    end

    it "returns a line for each event's user when adding a user field as a row" do
      user1 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nicole', last_name: 'Aldana'))
      user2 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nadia', last_name: 'Aldana'))
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interacitons: 50})
      event.users << [user1, user2]
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"user:first_name", "label"=>"First Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"user_first_name"=>"Nadia", "kpi_#{Kpi.impressions.id}"=>"100.00"},
        {"user_first_name"=>"Nicole", "kpi_#{Kpi.impressions.id}"=>"100.00"}
      ]
    end

    it "returns a line for each team's user when adding a user field as a row and the team is part of the event" do
      user1 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nicole', last_name: 'Aldana'))
      user2 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nadia', last_name: 'Aldana'))
      team = FactoryGirl.create(:team, company: company)
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interacitons: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interacitons: 300}) # Another event
      team.users << [user1, user2]
      event.teams << team
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"user:first_name", "label"=>"First Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"user_first_name"=>"Nadia", "kpi_#{Kpi.impressions.id}"=>"100.00"},
        {"user_first_name"=>"Nicole", "kpi_#{Kpi.impressions.id}"=>"100.00"},
        {"user_first_name"=>nil, "kpi_#{Kpi.impressions.id}"=>"300.00"}
      ]
    end

    it "returns a line for each team  when adding a team field as a row and the team is part of the event" do
      team = FactoryGirl.create(:team, name: 'Power Rangers', company: company)
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interacitons: 50})
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interacitons: 300}) # Another event
      event.teams << team
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"team:name", "label"=>"Team"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"team_name"=>"Power Rangers", "kpi_#{Kpi.impressions.id}"=>"100.00"}
      ]
    end

    it "should work when adding fields from users and teams" do
      user = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Green', last_name: 'Ranger'))
      team = FactoryGirl.create(:team, name: 'Power Rangers', company: company)
      team2 = FactoryGirl.create(:team, name: 'Transformers', company: company)
      team.users << user

      # A event with members but no teams
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interacitons: 50})
      event.users << user

      # A event with a team without members
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 200, interacitons: 100})
      event.teams << team2

      # A event with a team with members
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interacitons: 150})
      event.teams << team

      # A event without teams or members
      FactoryGirl.create(:event, campaign: campaign, results: {impressions: 300, interacitons: 150})
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"team:name", "label"=>"Team"}, {"field"=>"user:first_name", "label"=>"Team"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"team_name"=>"Power Rangers", "user_first_name"=>"Green", "kpi_#{Kpi.impressions.id}"=>"300.00"},
        {"team_name"=>"Transformers", "user_first_name"=>nil, "kpi_#{Kpi.impressions.id}"=>"200.00"},
        {"team_name"=>nil, "user_first_name"=>"Green", "kpi_#{Kpi.impressions.id}"=>"100.00"},
        {"team_name"=>nil, "user_first_name"=>nil, "kpi_#{Kpi.impressions.id}"=>"300.00"}
      ]
    end

    it "returns the values for each report's row" do
      user1 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nicole', last_name: 'Aldana'))
      user2 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nadia', last_name: 'Aldana'))
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interacitons: 50})
      event.users << [user1, user2]
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"user:last_name", "label"=>"Last Name"}, {"field"=>"user:first_name", "label"=>"First Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"user_last_name"=>"Aldana", "user_first_name"=>"Nadia", "kpi_#{Kpi.impressions.id}"=>"100.00"},
        {"user_last_name"=>"Aldana", "user_first_name"=>"Nicole", "kpi_#{Kpi.impressions.id}"=>"100.00"}
      ]
    end

    it "correctly handles multiple rows with fields from the event and users" do
      user1 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nicole', last_name: 'Aldana'))
      user2 = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user, first_name: 'Nadia', last_name: 'Aldana'))
      event = FactoryGirl.create(:event, campaign: campaign, results: {impressions: 100, interacitons: 50})
      event.users << [user1, user2]
      report = FactoryGirl.create(:report,
        company: company,
        rows:    [{"field"=>"event:start_date", "label"=>"Start date"}, {"field"=>"user:first_name", "label"=>"First Name"}],
        values:  [{"field"=>"kpi:#{Kpi.impressions.id}", "label"=>"Impressions", "aggregate"=>"sum"}]
      )
      page = report.fetch_page
      expect(page).to eql [
        {"event_start_date"=>"2019/01/23", "user_first_name"=>"Nadia", "kpi_#{Kpi.impressions.id}"=>"100.00"},
        {"event_start_date"=>"2019/01/23", "user_first_name"=>"Nicole", "kpi_#{Kpi.impressions.id}"=>"100.00"}
      ]
    end
  end
end
