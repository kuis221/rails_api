require 'spec_helper'

describe BrandsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  describe "campaign scope" do
    let(:campaign) { FactoryGirl.create(:campaign, company: @company) }

    describe "GET 'new'" do
      it "returns http success" do
        get 'index', campaign_id: campaign.to_param, format: :json
        response.should be_success
        response.should render_template('index')
      end
    end
  end

  describe "brand portfolio scope" do
    let(:brand_portfolio) { FactoryGirl.create(:brand_portfolio, company: @company) }

    describe "GET 'new'" do
      it "returns http success" do
        get 'new', brand_portfolio_id: brand_portfolio.to_param, format: :js
        response.should be_success
        response.should render_template('new')
        response.should render_template('form')
      end
    end

    describe "POST 'create'" do
      it "should assign the new brand to the brand portfolio" do
        expect {
          expect {
            post 'create', brand_portfolio_id: brand_portfolio.to_param, brand: {name: 'test brand'}, format: :js
          }.to change(Brand, :count).by(1)
        }.to change(brand_portfolio.brands, :count).by(1)
      end
    end
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
      parsed_body.map{|b| b['name']}.should == ['Brand 123', 'Brand 456']
    end

    it "returns the brands associated to a brand portfolio" do
      brand_portfolio.brands << FactoryGirl.create(:brand, name: 'Brand 123')
      brand_portfolio.brands << FactoryGirl.create(:brand, name: 'Brand 456')
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 871')
      FactoryGirl.create(:brand, name: 'Brand 789')

      get 'index', brand_portfolio_id: brand_portfolio.id, format: :json

      response.should be_success
      parsed_body = JSON.parse(response.body)
      parsed_body.count.should == 2
      parsed_body.map{|b| b['name']}.should == ['Brand 123', 'Brand 456']
    end
  end

end
