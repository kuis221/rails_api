require 'spec_helper'

describe Api::V1::SessionsController do
  describe "POST create" do
    let(:user) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, password: 'PassDePrueba45', password_confirmation: 'PassDePrueba45'), company: FactoryGirl.create(:company) ).user }
    let(:company) { user.companies.first }
    it "should return the authentication token if success" do
      expect(user.reload.current_company_id).to be_nil
      post :create, email: user.email, password: 'PassDePrueba45', format: :json
      expect(user.reload.authentication_token).to_not be_nil
      result = JSON.parse(response.body)
      response.should be_success
      result['success'].should be_true
      result['info'].should == 'Logged in'
      result['data']['auth_token'].should == user.authentication_token
      result['data']['current_company_id'].should == company.id

      # It should set the current_company_id if nil
      expect(user.reload.current_company_id).to eql user.companies.first.id
    end

    it "should return the current_company_id" do
      # Add the user to another company
      other_company = FactoryGirl.create(:company_user, user: user, company_id: FactoryGirl.create(:company).id).company
      user.update_column(:current_company_id, other_company.id)

      post :create, email: user.email, password: 'PassDePrueba45', format: :json
      result = JSON.parse(response.body)
      response.should be_success
      result['success'].should be_true
      result['data']['current_company_id'].should == other_company.id
    end

    it "should fix the current_company_id if not valid" do
      user.update_column(:current_company_id, company.id+100)

      post :create, email: user.email, password: 'PassDePrueba45', format: :json
      result = JSON.parse(response.body)
      response.should be_success
      result['success'].should be_true
      result['data']['current_company_id'].should == company.id
    end

    it "should return an error if not success" do
      post :create, email: user.email, password: 'XXXXXXXX', format: :json
      result = JSON.parse(response.body)
      response.response_code.should == 401
      result['success'].should be_false
      result['info'].should == 'Login Failed'
      result['data'].should == {}
    end
  end

  describe "DELETE 'destroy'" do
    let(:user) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, password: 'PassDePrueba45', password_confirmation: 'PassDePrueba45', authentication_token: 'XYZ') ).user }

    it "should reset the authentication token" do
      delete :destroy, id: user.authentication_token, format: :json
      response.should be_success
      user.reload
      user.authentication_token.should_not == 'XYZ'
    end

    it "return 404 if the authentication token is not found" do
      delete :destroy, id: 'NOT_VALID', format: :json
      response.response_code.should == 404
      result = JSON.parse(response.body)
      result["sucess"].should be_false
      result["info"].should == "Invalid token."
    end
  end
end