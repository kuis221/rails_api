require 'spec_helper'

describe KpisController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', campaign_id: campaign.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'edit'" do
    let(:kpi){ FactoryGirl.create(:kpi, company: @company) }
    it "returns http success" do
      get 'edit',  campaign_id: campaign.to_param, id: kpi.to_param, format: :js
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "should not render form_dialog if no errors" do
      expect {
        expect {
          post 'create', campaign_id: campaign.to_param, kpi: {name: 'Test kpi', description: 'Test kpi description', kpi_type: 'number', goals_attributes: {0 => {campaign_id: campaign.to_param, value: 13}}}, format: :js
           response.should be_success
        }.to change(Kpi, :count).by(1)
      }.to change(Goal, :count).by(1)
      response.should be_success
      response.should render_template(:create)
      response.should_not render_template(:form_dialog)

      kpi = Kpi.last
      kpi.name.should == 'Test kpi'
      kpi.description.should == 'Test kpi description'

      goal = kpi.goals.first
      goal.campaign.should == campaign
    end

    it "should render the form_dialog template if errors" do
      lambda {
        post 'create', campaign_id: campaign.to_param, format: :js, kpi: {}
      }.should_not change(Kpi, :count)
      response.should render_template(:create)
      response.should render_template(:form_dialog)
      assigns(:kpi).errors.count > 0
    end
  end

  describe "PUT 'update'" do
    let(:kpi){ FactoryGirl.create(:kpi, company: @company) }
    it "must update the date_range attributes" do
      t = FactoryGirl.create(:kpi, company: @company)
      put 'update', campaign_id: campaign.to_param, id: kpi.to_param, kpi: {name: 'Test kpi', description: 'Test kpi description'}, format: :js
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)
      assigns(:kpi).should == kpi
      kpi.reload
      kpi.name.should == 'Test kpi'
      kpi.description.should == 'Test kpi description'
    end
  end
end
