require 'spec_helper'

describe RolesController do
  before(:each) do
    @user = sign_in_as_user
  end

  describe "GET 'edit'" do
    let(:role){ FactoryGirl.create(:role) }
    it "returns http success" do
      get 'edit', id: role.to_param, format: :js
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

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end

    it "should successfully create the new record" do
      lambda {
        post 'create', role: {name: 'Test Role', description: 'Test Role description'}, format: :js
      }.should change(Role, :count).by(1)
      role = Role.last
      role.name.should == 'Test Role'
      role.description.should == 'Test Role description'
      role.active.should == true
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', role: {name: 'Test Role', description: 'Test Role description'}, format: :js
      }.should change(Role, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(Role, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:role).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:role){ FactoryGirl.create(:role) }

    it "deactivates an active role" do
      role.update_attribute(:active, true)
      get 'deactivate', id: role.to_param, format: :js
      response.should be_success
      role.reload.active?.should be_false
    end
  end

  describe "GET 'activate'" do
    let(:role){ FactoryGirl.create(:role, active: false) }

    it "activates an inactive `role" do
      role.active?.should be_false
      get 'activate', id: role.to_param, format: :js
      response.should be_success
      role.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    let(:role){ FactoryGirl.create(:role) }
    it "must update the role attributes" do
      put 'update', id: role.to_param, role: {name: 'New Role Name', description: 'New description for Role'}
      assigns(:role).should == role
      response.should redirect_to(role_path(role))
      role.reload
      role.name.should == 'New Role Name'
      role.description.should == 'New description for Role'
    end
  end
end
