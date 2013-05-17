require 'spec_helper'

describe CampaignsController do
  before(:each) do
    @user = sign_in_as_user
  end

  describe "GET 'edit'" do
    let(:campaign){ FactoryGirl.create(:campaign) }
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

    describe "datatable requests" do
      it "responds to .table format" do
        get 'index', format: :table
        response.should be_success
      end

      it "returns the correct structure" do
        FactoryGirl.create_list(:campaign, 3)
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

  describe "GET 'deactivate'" do
    let(:campaign){ FactoryGirl.create(:campaign) }

    it "deactivates an active campaign" do
      campaign.update_attribute(:aasm_state, 'active')
      get 'deactivate', id: campaign.to_param, format: :js
      response.should be_success
      campaign.reload.active?.should be_false
    end
  end

  describe "GET 'activate'" do
    let(:campaign){ FactoryGirl.create(:campaign,aasm_state: 'inactive') }

    it "activates an inactive campaign" do
      campaign.active?.should be_false
      get 'activate', id: campaign.to_param, format: :js
      response.should be_success
      campaign.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    let(:campaign){ FactoryGirl.create(:campaign) }
    it "must update the campaign attributes" do
      t = FactoryGirl.create(:campaign)
      put 'update', id: campaign.to_param, campaign: {name: 'Test Campaign', description: 'Test Campaign description'}
      assigns(:campaign).should == campaign
      response.should redirect_to(campaign_path(campaign))
      campaign.reload
      campaign.name.should == 'Test Campaign'
      campaign.description.should == 'Test Campaign description'
    end
  end
end
