require 'spec_helper'

describe Results::ReportsController do

  describe "GET 'index'" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.companies.first
      @company_user = @user.current_company_user
    end
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

end
