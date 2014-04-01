require 'spec_helper'

describe Results::GvaController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "POST 'report'" do
    let(:campaign){ FactoryGirl.create(:campaign, company: @company) }
    it "should return http success" do
      post 'report', report: {campaign_id: campaign.id}, format: :js
      response.should be_success
      response.should render_template('results/gva/report')
      response.should render_template('results/gva/_report')
    end
  end
end