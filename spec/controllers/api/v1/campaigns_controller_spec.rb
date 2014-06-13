require 'spec_helper'

describe Api::V1::CampaignsController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  describe "GET 'all'"do
    it "return a list of events" do
      campaign = FactoryGirl.create(:campaign, company: company, name: 'Cerveza Imperial FY14')
      FactoryGirl.create(:campaign, company: company, name: 'Cerveza Imperial FY14', aasm_state: 'closed')
      FactoryGirl.create(:campaign, company: company, name: 'Cerveza Imperial FY14', aasm_state: 'inactive')

      get :all, auth_token: user.authentication_token, company_id: company.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      expect(result).to match_array([{"id"=> campaign.id, "name"=>'Cerveza Imperial FY14'}])
    end
  end


  describe "GET 'overall_stats'"do
    before { Kpi.create_global_kpis }
    it "return a list of campaings with the info" do
      campaign = FactoryGirl.create(:campaign, company: company, name: 'Cerveza Imperial FY14')
      FactoryGirl.create(:campaign, company: company, name: 'Cerveza Imperial FY14', aasm_state: 'closed')
      FactoryGirl.create(:campaign, company: company, name: 'Cerveza Imperial FY14', aasm_state: 'inactive')

      FactoryGirl.create(:event, campaign: campaign)
      goal = campaign.goals.for_kpi(Kpi.events)
      goal.value = 200
      goal.save
      goal = campaign.goals.for_kpi(Kpi.promo_hours)
      goal.value = 100
      goal.save

      get :overall_stats, auth_token: user.authentication_token, company_id: company.to_param, format: :json
      response.should be_success
      results = JSON.parse(response.body)

      expect(results.first).to include({"id"=> campaign.id, "name"=>'Cerveza Imperial FY14', "goal" => 100.0, "kpi" => 'PROMO HOURS'})
      expect(results.second).to include({"id"=> campaign.id, "name"=>'Cerveza Imperial FY14', "goal" => 200.0, "kpi" => 'EVENTS'})
    end
  end

  describe "GET 'stats'"do
    before { Kpi.create_global_kpis }
    it "return a list of campaings with the info" do
      campaign = FactoryGirl.create(:campaign, company: company, name: 'Cerveza Imperial FY14')

      area = FactoryGirl.create(:area, name: 'California', company: company)
      area.places << FactoryGirl.create(:place, city: 'Los Angeles', state: 'California', types: ['political'])
      campaign.areas << area
      FactoryGirl.create(:goal, parent: campaign, goalable: area, kpi: Kpi.promo_hours, value: 10)

      get :stats, auth_token: user.authentication_token, company_id: company.to_param, id: campaign.to_param, format: :json
      response.should be_success
      stats = JSON.parse(response.body)

      expect(stats.first['id']).to eql area.id
      expect(stats.first['name']).to eql 'California'
      expect(stats.first['kpi']).to eql 'PROMO HOURS'
      expect(stats.first['goal']).to eql '10.0'
      expect(stats.first['executed']).to eql 0.0
      expect(stats.first['scheduled']).to eql 0.0
      expect(stats.first['remaining']).to eql '10.0'
      expect(stats.first['executed_percentage']).to eql 0
      expect(stats.first['scheduled_percentage']).to eql 0
      expect(stats.first['remaining_percentage']).to eql 100
      expect(stats.first.has_key?('today')).to be_false
      expect(stats.first.has_key?('today_percentage')).to be_false
     end
  end
end