require 'spec_helper'

describe AreasController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  let(:area){ FactoryGirl.create(:area, company: @company) }

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: area.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end

    describe "datatable requests" do
      it "responds to .json format" do
        get 'index', format: :json
        response.should be_success
      end

      it "returns the correct structure" do
        get 'index', sEcho: 1, format: :json
        parsed_body = JSON.parse(response.body)
        parsed_body["total"].should == 0
        parsed_body["items"].should == []
        parsed_body["pages"].should == 1
        parsed_body["page"].should == 1
      end
    end
  end

  describe "GET 'show'" do
    it "assigns the loads the correct objects and templates" do
      get 'show', id: area.id
      assigns(:area).should == area
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
        post 'create', area: {name: 'Test Area', description: 'Test Area description'}, format: :js
      }.should change(Area, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(Area, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:area).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    it "deactivates an active area" do
      area.update_attribute(:active, true)
      get 'deactivate', id: area.to_param, format: :js
      response.should be_success
      area.reload.active?.should be_false
    end

    it "activates an inactive area" do
      area.update_attribute(:active, false)
      get 'activate', id: area.to_param, format: :js
      response.should be_success
      area.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    it "must update the area attributes" do
      t = FactoryGirl.create(:area)
      put 'update', id: area.to_param, area: {name: 'Test Area', description: 'Test Area description'}
      assigns(:area).should == area
      response.should redirect_to(area_path(area))
      area.reload
      area.name.should == 'Test Area'
      area.description.should == 'Test Area description'
    end
  end

end