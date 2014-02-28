require 'spec_helper'

describe ActivityTypesController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }

  describe "GET 'edit'" do
    let(:activity_type){ FactoryGirl.create(:activity_type, company: @company) }
    it "returns http success" do
      get 'edit', campaign_id: campaign.to_param, id: activity_type.to_param, format: :js
      assigns(:campaign).should == campaign
      response.should be_success
    end
  end

  describe "PUT 'update'" do
    let(:activity_type){ FactoryGirl.create(:activity_type, company: @company) }
    it "must update the activity type attributes" do
      activity_type.save
      expect {
        expect {
          put 'update', campaign_id: campaign.to_param, id: activity_type.to_param,
              activity_type: {goal_attributes:
                {goalable_id: campaign.to_param, goalable_type: 'Campaign', activity_type_id: activity_type.to_param, value: 23}
              }, format: :js
        }.to change(Goal, :count).by(1)
      }.to_not change(ActivityType, :count)
      response.should render_template(:update)
      response.should_not render_template(:form_dialog)

      campaign.goals.for_activity_types([activity_type]).first.value.should == 23
      assigns(:activity_type).should == activity_type
    end
  end
end