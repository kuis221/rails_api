require 'spec_helper'

describe CampaignsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: campaign.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'items'" do
    it "returns http success" do
      get 'items'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end

    it "should successfully create the new record" do
      lambda {
        post 'create', campaign: {name: 'Test Campaign', description: 'Test Campaign description'}, format: :js
      }.should change(Campaign, :count).by(1)
      campaign = Campaign.last
      campaign.name.should == 'Test Campaign'
      campaign.description.should == 'Test Campaign description'
      campaign.aasm_state.should == 'inactive'
    end

    it "should not render form_dialog if no errors" do
      lambda {
        post 'create', campaign: {name: 'Test Campaign', description: 'Test Campaign description'}, format: :js
      }.should change(Campaign, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', format: :js
      }.should_not change(Campaign, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:campaign).errors.count > 0
    end
  end

  describe "GET 'show'" do
    it "assigns the loads the correct objects and templates" do
      get 'show', id: campaign.id
      assigns(:campaign).should == campaign
      response.should render_template(:show)
    end
  end

  describe "GET 'deactivate'" do

    it "deactivates an active campaign" do
      campaign.update_attribute(:aasm_state, 'active')
      get 'deactivate', id: campaign.to_param, format: :js
      response.should be_success
      campaign.reload.active?.should be_false
    end
  end

  describe "GET 'activate'" do
    let(:campaign){ FactoryGirl.create(:campaign, company: @company, aasm_state: 'inactive') }

    it "activates an inactive campaign" do
      campaign.active?.should be_false
      get 'activate', id: campaign.to_param, format: :js
      response.should be_success
      campaign.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    it "must update the campaign attributes" do
      t = FactoryGirl.create(:campaign, company: @company)
      put 'update', id: campaign.to_param, campaign: {name: 'Test Campaign', description: 'Test Campaign description'}
      assigns(:campaign).should == campaign
      response.should redirect_to(campaign_path(campaign))
      campaign.reload
      campaign.name.should == 'Test Campaign'
      campaign.description.should == 'Test Campaign description'
    end
  end


  describe "DELETE 'delete_member'" do
    it "should remove the team member from the campaign" do
      campaign.users << @company_user
      lambda{
        delete 'delete_member', id: campaign.id, member_id: @company_user.id, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should change(campaign.users, :count).by(-1)
    end

    it "should not raise error if the user doesn't belongs to the campaign" do
      delete 'delete_member', id: campaign.id, member_id: @user.id, format: :js
      campaign.reload
      response.should be_success
      assigns(:campaign).should == campaign
    end
  end

  describe "DELETE 'delete_member' with a team" do
    let(:team){ FactoryGirl.create(:team, company: @company) }
    it "should remove the team from the campaign" do
      campaign.teams << team
      lambda{
        delete 'delete_member', id: campaign.id, team_id: team.id, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should change(campaign.teams, :count).by(-1)
    end

    it "should not raise error if the team doesn't belongs to the campaign" do
      delete 'delete_member', id: campaign.id, team_id: team.id, format: :js
      campaign.reload
      response.should be_success
      assigns(:campaign).should == campaign
    end
  end

  describe "GET 'new_member" do
    it 'should load all the company\'s users into @users' do
      FactoryGirl.create(:user, company_id: @company.id+1)
      get 'new_member', id: campaign.id, format: :js
      response.should be_success
      assigns(:campaign).should == campaign
      assigns(:users).should == [@company_user]
    end

    it 'should not load the users that are already assigned ot the campaign' do
      another_user = FactoryGirl.create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
      campaign.users << @company_user
      get 'new_member', id: campaign.id, format: :js
      response.should be_success
      assigns(:campaign).should == campaign
      assigns(:users).should == [another_user]
    end

    it 'should load teams with active users' do
      team = FactoryGirl.create(:team, name:'123', company_id: @company.id)
      team.users << @company_user
      get 'new_member', id: campaign.id, format: :js
      assigns(:assignable_teams).should == [team]
      assigns(:staff).should == [team, @company_user]
    end

    it 'should not load teams without assignable users' do
      team = FactoryGirl.create(:team, company_id: @company.id)
      campaign.users << @company_user
      get 'new_member', id: campaign.id, format: :js
      assigns(:assignable_teams).should == []
      assigns(:staff).should == []
    end
  end


  describe "POST 'add_members" do

    it 'should assign the user to the campaign' do
      lambda {
        post 'add_members', id: campaign.id, member_id: @company_user.to_param, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should change(campaign.users, :count).by(1)
      campaign.users.should == [@company_user]
    end

    it 'should assign all the team\'s users to the campaign' do
      team = FactoryGirl.create(:team, company_id: @company.id)
      lambda {
        post 'add_members', id: campaign.id, team_id: team.to_param, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        assigns(:team_id).should == team.id.to_s
        campaign.reload
      }.should change(campaign.teams, :count).by(1)
      campaign.teams.should =~ [team]
    end

    it 'should not assign users to the campaign if they are already part of the campaign' do
      campaign.users << @company_user
      lambda {
        post 'add_members', id: campaign.id, member_id: @company_user.to_param, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should_not change(campaign.users, :count)
    end

    it 'should not assign teams to the campaign if they are already part of the campaign' do
      team = FactoryGirl.create(:team, company_id: @company.id)
      campaign.teams << team
      lambda {
        post 'add_members', id: campaign.id, team_id: team.to_param, format: :js
        response.should be_success
        assigns(:campaign).should == campaign
        campaign.reload
      }.should_not change(campaign.teams, :count)
    end
  end

end
