require 'spec_helper'

describe TeamsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:team){ FactoryGirl.create(:team, company: @company) }

  describe "GET 'edit'" do
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
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
      response.should be_success
      response.should render_template('new')
      response.should render_template('form')
    end
  end

  describe "GET 'items'" do
    it "returns http success" do
      get 'items'
      response.should be_success
    end
  end

  describe "GET 'show'" do
    it "assigns the loads the correct objects and templates" do
      get 'show', id: team.id
      assigns(:team).should == team
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
        post 'create', team: {name: 'Test Team', description: 'Test Team description'}, format: :js
      }.should change(Team, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      team = Team.last
      team.name.should == 'Test Team'
      team.description.should == 'Test Team description'
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(Team, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:team).errors.count.should > 0
    end
  end

  describe "GET 'deactivate'" do

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
    it "should remove the team member from the team" do
      team.users << @company_user
      lambda{
        delete 'delete_member', id: team.id, member_id: @company_user.id, format: :js
        response.should be_success
        assigns(:team).should == team
        team.reload
      }.should change(team.users, :count).by(-1)
    end

    it "should not raise error if the user doesn't belongs to the team" do
      delete 'delete_member', id: team.id, member_id: @company_user.id, format: :js
      team.reload
      response.should be_success
      assigns(:team).should == team
    end
  end

  describe "GET 'new_member" do
    it 'correctly assign the team' do
      get 'new_member', id: team.id, format: :js
      response.should be_success
      assigns(:team).should == team
      assigns(:staff).should == [{"id"=>@company_user.id.to_s, "name"=>"Test User", "description"=>"Super Admin", "type"=>"user"}]
    end

    it 'correctly assign the users' do
      users = FactoryGirl.create_list(:company_user, 3, company: @company, role_id: @company_user.role_id, active: true)
      users << @company_user # the current user should also appear on the list

      # Assign the users to other team
      other_team = FactoryGirl.create(:team, company: @company)
      users.each {|u| other_team.users << u}

      # Create some other users that should not be included
      FactoryGirl.create(:invited_user, company: @company, role_id: @company_user.role_id) # invited user
      FactoryGirl.create(:company_user, company: @company, role_id: @company_user.role_id, active: false) # inactive user
      FactoryGirl.create(:company_user, company_id: @company.id+1, role_id: @company_user.role_id, active: true) # user from other company
      get 'new_member', id: team.id, format: :js
      response.should be_success
      expect(assigns(:staff)).to  match_array users.map{|u| {'id' => u.id.to_s, 'name' => u.full_name, 'description' => u.role_name, 'type' => 'user'}}
    end

    it 'should not load the users that are already assigned ot the team' do
      another_user = FactoryGirl.create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
      team.users << @company_user
      get 'new_member', id: team.id, format: :js
      response.should be_success
      assigns(:team).should == team
      assigns(:staff).should == [{"id"=>another_user.id.to_s, "name"=>"Test User", "description"=>"Super Admin", "type"=>"user"}]
    end
  end


  describe "POST 'add_members" do
    it 'should assign the user to the team' do
      lambda {
        post 'add_members', id: team.id, member_id: @company_user.to_param, format: :js
        response.should be_success
        assigns(:team).should == team
        team.reload
      }.should change(team.users, :count).by(1)
      team.users.should == [@company_user]
    end

    it 'should not assign users to the team if they are already part of the team' do
      team.users << @company_user
      lambda {
        post 'add_members', id: team.id, member_id: @company_user.to_param, format: :js
        response.should be_success
        assigns(:team).should == team
        team.reload
      }.should_not change(team.users, :count)
    end
  end


end
