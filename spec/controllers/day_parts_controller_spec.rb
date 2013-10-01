require 'spec_helper'

describe DayPartsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
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

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
      response.should be_success
    end
  end

  describe "GET 'edit'" do
    let(:day_part){ FactoryGirl.create(:day_part, company: @company) }
    it "returns http success" do
      get 'edit', id: day_part.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'show'" do
    let(:day_part){ FactoryGirl.create(:day_part, company: @company) }
    it "assigns the loads the correct objects and templates" do
      get 'show', id: day_part.id
      assigns(:day_part).should == day_part
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
        post 'create', day_part: {name: 'Test day part', description: 'Test day part description'}, format: :js
      }.should change(DayPart, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      portfolio = DayPart.last
      portfolio.name.should == 'Test day part'
      portfolio.description.should == 'Test day part description'
      portfolio.active.should be_true
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(DayPart, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:day_part).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:day_part){ FactoryGirl.create(:day_part, company: @company) }

    it "deactivates an active day_part" do
      day_part.update_attribute(:active, true)
      get 'deactivate', id: day_part.to_param, format: :js
      response.should be_success
      day_part.reload.active?.should be_false
    end

    it "activates an inactive day_part" do
      day_part.update_attribute(:active, false)
      get 'activate', id: day_part.to_param, format: :js
      response.should be_success
      day_part.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    let(:day_part){ FactoryGirl.create(:day_part, company: @company) }

    it "must update the day_part attributes" do
      t = FactoryGirl.create(:day_part, company: @company)
      put 'update', id: day_part.to_param, day_part: {name: 'Test day part update', description: 'Test day part description update'}
      assigns(:day_part).should == day_part
      response.should redirect_to(day_part_path(day_part))
      day_part.reload
      day_part.name.should == 'Test day part update'
      day_part.description.should == 'Test day part description update'
    end
  end
end