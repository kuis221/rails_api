require 'spec_helper'

describe Results::GvaController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "POST 'report'" do
    let(:campaign){ FactoryGirl.create(:campaign, company: @company) }
    it "should return http success" do
      xhr :post, 'report', report: {campaign_id: campaign.id}, format: :js
      expect(response).to be_success
      expect(response).to render_template('results/gva/report')
      expect(response).to render_template('results/gva/_report')
    end

    it "should include any goals for the campaign" do
      kpi = FactoryGirl.create(:kpi, company: campaign.company)
      events = FactoryGirl.create_list(:event, 3, campaign: campaign)
      FactoryGirl.create_list(:event, 2, campaign: FactoryGirl.create(:campaign, company: campaign.company))

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save
      xhr :post, 'report', report: {campaign_id: campaign.id}, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [goal]
    end

    it "should include only goals for the given user" do
      kpi = FactoryGirl.create(:kpi, company: campaign.company)
      events = FactoryGirl.create_list(:event, 3, campaign: campaign)
      FactoryGirl.create_list(:event, 2, campaign: FactoryGirl.create(:campaign, company: campaign.company))

      user = FactoryGirl.create(:company_user, company: campaign.company)

      events.each{|e| e.users << user }

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save

      user_goal = user.goals.for_kpi(kpi)
      user_goal.parent = campaign
      user_goal.value = 100
      user_goal.save

      xhr :post, 'report', report: {campaign_id: campaign.id}, item_type: 'CompanyUser', item_id: user.id, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [user_goal]
    end

    it "should include only goals for the given team" do
      kpi = FactoryGirl.create(:kpi, company: campaign.company)
      events = FactoryGirl.create_list(:event, 3, campaign: campaign)
      FactoryGirl.create_list(:event, 2, campaign: FactoryGirl.create(:campaign, company: campaign.company))

      team = FactoryGirl.create(:team, company: campaign.company)

      events.each{|e| e.teams << team }

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save

      team_goal = team.goals.for_kpi(kpi)
      team_goal.parent = campaign
      team_goal.value = 100
      team_goal.save

      xhr :post, 'report', report: {campaign_id: campaign.id}, item_type: 'Team', item_id: team.id, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [team_goal]
    end


    it "should include only goals for the given area" do
      kpi = FactoryGirl.create(:kpi, company: campaign.company)
      place = FactoryGirl.create(:place)
      events = FactoryGirl.create_list(:event, 3, campaign: campaign, place: place)
      FactoryGirl.create_list(:event, 2, campaign: FactoryGirl.create(:campaign, company: campaign.company))

      area = FactoryGirl.create(:area, company: campaign.company)
      area.places << place

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save

      area_goal = area.goals.for_kpi(kpi)
      area_goal.parent = campaign
      area_goal.value = 100
      area_goal.save

      xhr :post, 'report', report: {campaign_id: campaign.id}, item_type: 'Area', item_id: area.id, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [area_goal]
    end

    it "should include only goals for the given place" do
      kpi = FactoryGirl.create(:kpi, company: campaign.company)
      place = FactoryGirl.create(:place)
      events = FactoryGirl.create_list(:event, 3, campaign: campaign, place: place)
      FactoryGirl.create_list(:event, 2, campaign: FactoryGirl.create(:campaign, company: campaign.company))

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save

      place_goal = place.goals.for_kpi(kpi)
      place_goal.parent = campaign
      place_goal.value = 100
      place_goal.save

      xhr :post, 'report', report: {campaign_id: campaign.id}, item_type: 'Place', item_id: place.id, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [place_goal]
    end
  end
end