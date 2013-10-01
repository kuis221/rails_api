require 'spec_helper'

describe DateRangesController do
before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  describe "GET 'edit'" do
    let(:date_range){ FactoryGirl.create(:date_range, company: @company) }
    it "returns http success" do
      get 'edit', id: date_range.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
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
    end
  end

  describe "GET 'show'" do
    let(:date_range){ FactoryGirl.create(:date_range, company: @company) }
    it "assigns the loads the correct objects and templates" do
      get 'show', id: date_range.id
      assigns(:date_range).should == date_range
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
        post 'create', date_range: {name: 'Test brand portfolio', description: 'Test brand portfolio description'}, format: :js
      }.should change(DateRange, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      portfolio = DateRange.last
      portfolio.name.should == 'Test brand portfolio'
      portfolio.description.should == 'Test brand portfolio description'
      portfolio.active.should be_true
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(DateRange, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:date_range).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:date_range){ FactoryGirl.create(:date_range, company: @company) }

    it "deactivates an active date_range" do
      date_range.update_attribute(:active, true)
      get 'deactivate', id: date_range.to_param, format: :js
      response.should be_success
      date_range.reload.active?.should be_false
    end

    it "activates an inactive date_range" do
      date_range.update_attribute(:active, false)
      get 'activate', id: date_range.to_param, format: :js
      response.should be_success
      date_range.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    let(:date_range){ FactoryGirl.create(:date_range, company: @company) }
    it "must update the date_range attributes" do
      t = FactoryGirl.create(:date_range, company: @company)
      put 'update', id: date_range.to_param, date_range: {name: 'Test date_range', description: 'Test date_range description'}
      assigns(:date_range).should == date_range
      response.should redirect_to(date_range_path(date_range))
      date_range.reload
      date_range.name.should == 'Test date_range'
      date_range.description.should == 'Test date_range description'
    end
  end


end
