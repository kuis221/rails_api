require 'spec_helper'

describe TeamsController do
  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe "GET 'edit'" do
    let(:team){ FactoryGirl.create(:team) }
    it "returns http success" do
      get 'edit', id: team.to_param, format: :js
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
        FactoryGirl.create_list(:team, 3)
        get 'index', sEcho: 1, format: :table
        parsed_body = JSON.parse(response.body)
        parsed_body["sEcho"].should == 1
        parsed_body["iTotalRecords"].should == 3
        parsed_body["iTotalDisplayRecords"].should == 3
        parsed_body["aaData"].count.should == 3
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
        post 'create', team: {name: 'Test Team', description: 'Test Team description'}, format: :js
      }.should change(Team, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(Team, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:team).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:team){ FactoryGirl.create(:team) }

    it "deactivates an active team" do
      team.update_attribute(:active, true)
      get 'deactivate', id: team.to_param, format: :js
      response.should be_success
      team.reload.active?.should be_false
    end

    it "activates an inactive team" do
      team.update_attribute(:active, false)
      get 'deactivate', id: team.to_param, format: :js
      response.should be_success
      team.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    let(:team){ FactoryGirl.create(:team) }
    it "must update the team attributes" do
      t = FactoryGirl.create(:team)
      put 'update', id: team.to_param, team: {name: 'Test Team', description: 'Test Team description'}
      assigns(:team).should == team
      response.should redirect_to(team_path(team))
      team.reload
      team.name.should == 'Test Team'
      team.description.should == 'Test Team description'
    end
  end

end
