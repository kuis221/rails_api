require 'spec_helper'

describe BrandPortfoliosController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  describe "GET 'edit'" do
    let(:brand_portfolio){ FactoryGirl.create(:brand_portfolio, company: @company) }
    it "returns http success" do
      get 'edit', id: brand_portfolio.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end

    describe "json requests" do
      it "responds to .json format" do
        get 'index', format: :json
        response.should be_success
      end

      it "returns the correct structure" do
        get 'index', format: :json
        parsed_body = JSON.parse(response.body)
        parsed_body["total"].should == 0
        parsed_body["items"].should == []
        parsed_body["pages"].should == 1
        parsed_body["page"].should == 1
      end
    end
  end

  describe "GET 'select_brands'" do
    let(:brand_portfolio){ FactoryGirl.create(:brand_portfolio, company: @company) }
    it "returns http success" do
      get 'select_brands', id: brand_portfolio.to_param, format: :js
      response.should be_success
      assigns(:brand_portfolio).should == brand_portfolio
    end
  end

  describe "POST 'add_brands'" do
    let(:brand_portfolio){ FactoryGirl.create(:brand_portfolio, company: @company) }
    it "should add the brand to the portfolio" do
      brand = FactoryGirl.create(:brand)
      expect {
        post 'add_brands', id: brand_portfolio.to_param, brand_id: brand.to_param, format: :js
      }.to change(BrandPortfoliosBrand, :count).by(1)
      response.should be_success
      assigns(:brand_portfolio).should == brand_portfolio
      brand_portfolio.brands.should == [brand]
    end

    it "should not add duplicated brands to portfolios" do
      brand = FactoryGirl.create(:brand)
      brand_portfolio.brands << brand
      expect {
        post 'add_brands', id: brand_portfolio.to_param, brand_id: brand.to_param, format: :js
      }.to_not change(BrandPortfoliosBrand, :count)
      response.should be_success
      assigns(:brand_portfolio).should == brand_portfolio
      brand_portfolio.reload.brands.should == [brand]
    end
  end

  describe "GET 'show'" do
    let(:brand_portfolio){ FactoryGirl.create(:brand_portfolio, company: @company) }
    it "assigns the loads the correct objects and templates" do
      get 'show', id: brand_portfolio.id
      assigns(:brand_portfolio).should == brand_portfolio
      response.should render_template(:show)
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', brand_portfolio: {name: 'Test brand portfolio', description: 'Test brand portfolio description'}, format: :js
      }.should change(BrandPortfolio, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      portfolio = BrandPortfolio.last
      portfolio.name.should == 'Test brand portfolio'
      portfolio.description.should == 'Test brand portfolio description'
      portfolio.active.should be_true
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(BrandPortfolio, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:brand_portfolio).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:brand_portfolio){ FactoryGirl.create(:brand_portfolio, company: @company) }

    it "deactivates an active brand_portfolio" do
      brand_portfolio.update_attribute(:active, true)
      get 'deactivate', id: brand_portfolio.to_param, format: :js
      response.should be_success
      brand_portfolio.reload.active?.should be_false
    end

    it "activates an inactive brand_portfolio" do
      brand_portfolio.update_attribute(:active, false)
      get 'activate', id: brand_portfolio.to_param, format: :js
      response.should be_success
      brand_portfolio.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    let(:brand_portfolio){ FactoryGirl.create(:brand_portfolio, company: @company) }
    it "must update the brand_portfolio attributes" do
      t = FactoryGirl.create(:brand_portfolio)
      put 'update', id: brand_portfolio.to_param, brand_portfolio: {name: 'Test brand_portfolio', description: 'Test brand_portfolio description'}
      assigns(:brand_portfolio).should == brand_portfolio
      response.should redirect_to(brand_portfolio_path(brand_portfolio))
      brand_portfolio.reload
      brand_portfolio.name.should == 'Test brand_portfolio'
      brand_portfolio.description.should == 'Test brand_portfolio description'
    end
  end

end
