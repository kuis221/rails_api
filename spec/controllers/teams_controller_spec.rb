require 'spec_helper'

describe TeamsController do
  before(:each) do
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id)
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

    describe "json requests" do
      it "responds to .json format" do
        get 'index', format: :json
        response.should be_success
      end

      it "returns the correct structure" do
        FactoryGirl.create_list(:team, 3)

        # Teams on other companies should not be included on the results
        FactoryGirl.create_list(:team, 2, company_id: 9999)

        get 'index', format: :json
        parsed_body = JSON.parse(response.body)
        parsed_body["total"].should == 3
        parsed_body["items"].count.should == 3
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
      get 'activate', id: team.to_param, format: :js
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


  describe "DELETE 'delete_member'" do
    let(:team){ FactoryGirl.create(:team) }
    it "should remove the team member from the team" do
      team.users << @user
      lambda{
        delete 'delete_member', id: team.id, member_id: @user.id, format: :js
        response.should be_success
        assigns(:team).should == team
        team.reload
      }.should change(team.users, :count).by(-1)
    end

    it "should not raise error if the user doesn't belongs to the team" do
      delete 'delete_member', id: team.id, member_id: @user.id, format: :js
      team.reload
      response.should be_success
      assigns(:team).should == team
    end
  end

  describe "GET 'new_member" do
    let(:team){ FactoryGirl.create(:team, company: @user.company) }
    it 'correctly assign the team' do
      get 'new_member', id: team.id, format: :js
      response.should be_success
      assigns(:team).should == team
    end

    it 'correctly assign the roles' do
      roles = FactoryGirl.create_list(:role, 3, company: @user.company, active: true)

      # Create some other roles that should not be included
      FactoryGirl.create(:role,company: @user.company, active: false) # inactive role
      FactoryGirl.create(:role,company_id: @user.company_id + 1, active: true) # role from other company

      get 'new_member', id: team.id, format: :js
      assigns(:roles).should =~ roles
    end

    it 'correctly assign the users' do
      users = FactoryGirl.create_list(:user, 3, company: @user.company, aasm_state: 'active')
      users << @user # the current user should also appear on the list

      # Assign the users to other team
      other_team = FactoryGirl.create(:team, company: @user.company)
      users.each {|u| other_team.users << u}

      # Create some other roles that should not be included
      FactoryGirl.create(:user, company: @user.company, aasm_state: 'invited') # invited user
      FactoryGirl.create(:user, company: @user.company, aasm_state: 'inactive') # inactive user
      FactoryGirl.create(:user, company_id: @user.company_id+1, aasm_state: 'active') # user from other company
      get 'new_member', id: team.id, format: :js
      response.should be_success
      assigns(:users).should =~ users
    end
  end


  describe "POST 'add_members" do
    let(:team){ FactoryGirl.create(:team) }
    it 'should assign the user to the team' do
      lambda {
        post 'add_members', id: team.id, member_id: @user.to_param, format: :js
        response.should be_success
        assigns(:team).should == team
        assigns(:members).should == [@user]
        team.reload
      }.should change(team.users, :count).by(1)
    end

    it 'should not assign users to the team if they are already part of the team' do
      team = FactoryGirl.create(:team, company_id: @user.company_id)
      team.users << @user
      lambda {
        post 'add_members', id: team.id, member_id: @user.to_param, format: :js
        response.should be_success
        assigns(:team).should == team
        assigns(:members).should =~ [@user]
        team.reload
      }.should_not change(team.users, :count)
    end
  end


end
