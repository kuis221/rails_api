require 'spec_helper'

describe Results::PhotosController do
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

  describe "GET 'items'" do
    it "should return http success" do
      get 'items'
      response.should be_success
      response.should render_template('results/photos/items')
    end
  end

end