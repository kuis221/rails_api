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
end