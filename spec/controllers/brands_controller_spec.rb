require 'spec_helper'

describe BrandsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  describe "GET 'index'" do
    let(:campaign) { FactoryGirl.create(:campaign, company: @company) }
    it "returns http success" do
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 123')
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 456')
      FactoryGirl.create(:brand, name: 'Brand 789')

      get 'index', campaign_id: campaign.id, format: :json

      response.should be_success
      parsed_body = JSON.parse(response.body)
      parsed_body.count.should == 2
      parsed_body.map{|b| b['name']}.should == ['Brand 123', 'Brand 456']
    end
  end

end
