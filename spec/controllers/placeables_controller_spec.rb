require 'spec_helper'

describe PlaceablesController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  describe "GET #new" do
    let(:campaign) { FactoryGirl.create(:campaign, company: @company) }

    it "do not include the areas that belongs to the campaign" do
      area = FactoryGirl.create(:area, company: @company)
      assigned_area = FactoryGirl.create(:area, company: @company)
      campaign.areas << assigned_area
      get :new, campaign_id: campaign.id, format: :js

      assigns(:areas).should == [area]
    end
  end
end
