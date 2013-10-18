require 'spec_helper'

describe Api::V1::SessionsController do
  let(:user) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, password: 'PassDePrueba45', password_confirmation: 'PassDePrueba45') ).user }
  it "should return the authentication token if success" do
    post :create, email: user.email, password: 'PassDePrueba45', format: :json
    user.reload.authentication_token.should_not be_nil
    result = JSON.parse(response.body)
    result['success'].should be_true
    result['info'].should == 'Logged in'
    result['data']['auth_token'].should == user.authentication_token
  end

  it "should return an error if not success" do
    post :create, email: user.email, password: 'XXXXXXXX', format: :json
    user.reload.authentication_token.should be_nil
    result = JSON.parse(response.body)
    result['success'].should be_false
    result['info'].should == 'Login Failed'
    result['data'].should == {}
  end
end