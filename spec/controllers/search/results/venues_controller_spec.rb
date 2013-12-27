require 'spec_helper'

describe VenuesController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'filters'" do
    it "should return the correct buckets in the right order" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      event = FactoryGirl.create(:event, place: FactoryGirl.create(:place), campaign: campaign, company: @company)
      Sunspot.commit
      get 'filters', format: :json
      response.should be_success

      # TODO: make this test to return the ranges filters as well

      filters = JSON.parse(response.body)
      filters['filters'].map{|b| b['label']}.should == ["Events", "Impressions", "Interactions", "Promo Hours", "Samples", "Venue Score", "$ Spent", "Price", "Locations", "Campaigns", "Brands"]
    end
  end

end