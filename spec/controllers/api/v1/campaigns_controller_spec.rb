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
end