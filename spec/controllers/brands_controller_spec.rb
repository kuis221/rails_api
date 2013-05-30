require 'spec_helper'

describe BrandsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  describe "GET 'index'" do
    let(:campaign) { FactoryGirl.create(:campaign, company: @company) }
    let(:brand_portfolio) { FactoryGirl.create(:brand_portfolio, company: @company) }
    it "returns the brands associated to a campaign" do
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 123')
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 456')
      brand_portfolio.brands << FactoryGirl.create(:brand, name: 'Brand 871')
      FactoryGirl.create(:brand, name: 'Brand 789')

      get 'index', campaign_id: campaign.id, format: :json

      response.should be_success
      parsed_body = JSON.parse(response.body)
      parsed_body.count.should == 2
      parsed_body['items'].map{|b| b['name']}.should == ['Brand 123', 'Brand 456']
    end

    it "returns the brands associated to a brand portfolio" do
      brand_portfolio.brands << FactoryGirl.create(:brand, name: 'Brand 123')
      brand_portfolio.brands << FactoryGirl.create(:brand, name: 'Brand 456')
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 871')
      FactoryGirl.create(:brand, name: 'Brand 789')

      get 'index', brand_portfolio_id: campaign.id, format: :json

      response.should be_success
      parsed_body = JSON.parse(response.body)
      parsed_body.count.should == 2
      parsed_body['items'].map{|b| b['name']}.should == ['Brand 123', 'Brand 456']
    end
  end

end
