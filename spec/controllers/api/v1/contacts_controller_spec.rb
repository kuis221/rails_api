require 'spec_helper'

describe Api::V1::ContactsController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:contact) { FactoryGirl.create(:contact, company: company) }
  describe "GET 'index'" do
    it "should return failure for invalid authorization token" do
      get :index, company_id: company.id, auth_token: 'XXXXXXXXXXXXXXXX', format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "returns the current user in the results" do
      contact.reload
      get :index, company_id: company.id, auth_token: user.authentication_token, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result.should == [{
        "id" => contact.id,
        "first_name" => contact.first_name,
        "last_name" => contact.last_name,
        "full_name" => contact.full_name,
        "title" => contact.title,
        "email" => contact.email,
        "phone_number" => contact.phone_number,
        "street_address" => contact.street_address,
        "city" => contact.city,
        "state" => contact.state,
        "zip_code" => contact.zip_code,
        "country" => contact.country_name}]
    end
  end
end
