require 'spec_helper'

describe Results::EventStatusController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      response.should be_success
    end
  end
  
  let(:campaign) { FactoryGirl.create(:campaign, company: @company, name: 'Test Campaign FY01') }
  describe "POST 'index'" do
    it "should return http success" do
      Sunspot.commit
      post 'index', "report"=>{"campaign_id"=>campaign.id}
      response.should be_success
    end
  end
end