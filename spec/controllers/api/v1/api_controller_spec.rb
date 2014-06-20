require 'spec_helper'

describe Api::V1::ApiController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  controller(Api::V1::ApiController) do
    skip_authorize_resource
    skip_authorization_check
    def index
    end

    def test_record_not_found
      raise ActiveRecord::RecordNotFound
    end
  end

  describe "handling InvalidAuthToken exception" do
    it "renders failure HTTP Unauthorized" do
      get :index, auth_token: 'XXXXXXXXXXXXXXXX', company_id: @company.to_param, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end
  end

  describe "handling InvalidCompany exception" do
    it "renders failure HTTP Unauthorized" do
      get :index, auth_token: @user.authentication_token, company_id: @company.id+1, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid company'
      result['data'].should be_empty
    end
  end

  describe "handling RecordNotFound exception" do
    before do
      routes.draw { get "test_record_not_found" => "anonymous#test_record_not_found" }
    end
    it "renders failure HTTP Not Found" do
      get :test_record_not_found, format: :json
      response.response_code.should == 404
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Record not found'
      result['data'].should be_empty
    end
  end
end