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
            post 'create', brand_portfolio_id: brand_portfolio.to_param, brand: {name: 'Test Brand', marques_list: 'Marque 1'}, format: :js
          }.to change(Brand, :count).by(1)
        }.to change(brand_portfolio.brands, :count).by(1)
      end
    end
  end

  describe "GET 'edit'" do
    let(:brand){ FactoryGirl.create(:brand, company: @company) }
    it "returns http success" do
      get 'edit', id: brand.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'items'" do
    it "returns the correct structure" do
      get 'items'
      response.should be_success
    end
  end

  describe "GET 'show'" do
    let(:brand){ FactoryGirl.create(:brand, company: @company) }
    it "assigns the loads the correct objects and templates" do
      get 'show', id: brand.id
      assigns(:brand).should == brand
      response.should render_template(:show)
    end
  end

  describe "GET 'index'" , search: true do
    let(:campaign) { FactoryGirl.create(:campaign, company: @company) }
    let(:brand_portfolio) { FactoryGirl.create(:brand_portfolio, company: @company) }
    it "returns the brands associated to a campaign" do
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 123', company: @company)
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 456', company: @company)
      brand_portfolio.brands << FactoryGirl.create(:brand, name: 'Brand 871', company: @company)
      FactoryGirl.create(:brand, name: 'Brand 789', company: @company)
      Sunspot.commit
      get 'index', campaign_id: campaign.id, format: :json

      response.should be_success
      parsed_body = JSON.parse(response.body)
      parsed_body.count.should == 2
      parsed_body.map{|b| b['name']}.should == ['Brand 456', 'Brand 123']
    end

    it "returns the brands associated to a brand portfolio" do
      brand_portfolio.brands << FactoryGirl.create(:brand, name: 'Brand 123', company: @company)
      brand_portfolio.brands << FactoryGirl.create(:brand, name: 'Brand 456', company: @company)
      campaign.brands << FactoryGirl.create(:brand, name: 'Brand 871', company: @company)
      FactoryGirl.create(:brand, name: 'Brand 789', company: @company)
      Sunspot.commit
      get 'index', brand_portfolio_id: brand_portfolio.id, format: :json

      response.should be_success
      parsed_body = JSON.parse(response.body)
      parsed_body.count.should == 2
      parsed_body.map{|b| b['name']}.should == ['Brand 456', 'Brand 123']
    end
  end

  describe "GET 'deactivate'" do
    let(:brand){ FactoryGirl.create(:brand, company: @company) }

    it "deactivates an active brand" do
      brand.update_attribute(:active, true)
      get 'deactivate', id: brand.to_param, format: :js
      response.should be_success
      brand.reload.active?.should be_falsey
    end

    it "activates an inactive brand" do
      brand.update_attribute(:active, false)
      get 'activate', id: brand.to_param, format: :js
      response.should be_success
      brand.reload.active?.should be_truthy
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', brand: {name: 'Test Brand', marques_list: 'Marque 1,Marque 2'}, format: :js
      }.should change(Brand, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      brand = Brand.last
      brand.name.should == 'Test Brand'
      brand.marques.all.map(&:name).should =~ ['Marque 1','Marque 2']
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(Brand, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:brand).errors.count.should > 0
    end
  end

  describe "PUT 'update'" do
    let(:brand){ FactoryGirl.create(:brand, company: @company) }
    it "must update the brand attributes" do
      put 'update', id: brand.to_param, brand: {name: 'Test brand', marques_list: 'Marque 1'}
      assigns(:brand).should == brand
      brand.reload
      brand.name.should == 'Test brand'
      brand.marques.all.map(&:name).should =~ ['Marque 1']
    end
  end
end