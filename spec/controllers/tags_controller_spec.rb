require 'spec_helper'

describe TagsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @tag = FactoryGirl.create(:tag, name: 'tag1', company_id: @company )
    @event = FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company)) 
    @attached_asset =  FactoryGirl.create(:attached_asset, attachable: @event) 
  end
  
  

  describe "GET 'deactivate'" do
    
    it "deactivates an active tag" do
      @attached_asset.tags << @tag
      get 'deactivate', id: @tag.to_param, attached_asset_id: @attached_asset.to_param, format: :js
      response.should be_success
      #campaign.reload.active?.should be_false
    end
  end

  describe "GET 'activate'" do

    it "activates an inactive campaign" do
      get 'activate', id: @tag.to_param, attached_asset_id: @attached_asset.to_param, format: :js
      response.should be_success
      #campaign.reload.active?.should be_true
    end
  end
end
