require 'spec_helper'

describe UsersController do
  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe "GET 'edit'" do
    let(:user){ FactoryGirl.create(:user) }
    it "returns http success" do
      get 'edit', id: user.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end

    describe "datatable requests" do
      it "responds to .table format" do
        get 'index', format: :table
        response.should be_success
      end

      it "returns the correct structure" do
        FactoryGirl.create_list(:user, 3)
        get 'index', sEcho: 1, format: :table
        parsed_body = JSON.parse(response.body)
        parsed_body["sEcho"].should == 1
        parsed_body["iTotalRecords"].should == 4
        parsed_body["iTotalDisplayRecords"].should == 4
        parsed_body["aaData"].count.should == 4
      end
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com'}, format: :js
      }.should change(User, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(User, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:user).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:user){ FactoryGirl.create(:user) }

    it "deactivates an active user" do
      user.update_attribute(:aasm_state, 'active')
      get 'deactivate', id: user.to_param, format: :js
      response.should be_success
      user.reload.active?.should be_false
    end

    it "activates an inactive user" do
      user.update_attribute(:aasm_state, 'inactive')
      get 'deactivate', id: user.to_param, format: :js
      response.should be_success
      user.reload.active?.should be_true
    end
  end


  describe "PUT 'update'" do
    let(:user){ FactoryGirl.create(:user) }
    it "must update the user attributes" do
      put 'update', id: user.to_param, user: {first_name: 'Juanito', last_name: 'Perez'}
      assigns(:user).should == user
      response.should redirect_to(user_path(user))
      user.reload
      user.first_name.should == 'Juanito'
      user.last_name.should == 'Perez'
    end
  end

end
