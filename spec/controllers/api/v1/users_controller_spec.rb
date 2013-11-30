require 'spec_helper'

describe Api::V1::UsersController do
  let(:user) { sign_in_as_user }

  describe "POST 'new_password'" do
    it "should return failure for a non-existent user" do
      Devise::Mailer.should_not_receive(:reset_password_instructions)
      post 'new_password', email:"fake@email.com", format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Action Failed'
      result['data'].should be_empty
    end

    it "should return failure for an inactive user" do
      Devise::Mailer.should_not_receive(:reset_password_instructions)
      inactive_user = FactoryGirl.create(:company_user, company: FactoryGirl.create(:company), user: FactoryGirl.create(:user), active: false)
      post 'new_password', email: inactive_user.email, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Action Failed'
      result['data'].should be_empty
    end

    it "should return failure for an active user with inactive role" do
      Devise::Mailer.should_not_receive(:reset_password_instructions)
      company = FactoryGirl.create(:company)
      inactive_user = FactoryGirl.create(:company_user, company: company, user: FactoryGirl.create(:user), role: FactoryGirl.create(:role, company: company, active: false))
      post 'new_password', email: inactive_user.email, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Action Failed'
      result['data'].should be_empty
    end

    it "should send reset password instructions to the user" do
      Devise::Mailer.should_receive(:reset_password_instructions).and_return(double(deliver: true))
      post 'new_password', email: user.email, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result['success'].should == true
      result['info'].should == 'Reset password instructions sent'
      result['data'].should be_empty

      user.reload
      user.reset_password_token.should_not be_nil
    end
  end

  describe "GET 'companies'" do
    it "should return failure for invalid authorization token" do
      get 'companies', auth_token: 'XXXXXXXXXXXXXXXX', format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "should return list of companies associated to the current logged in user" do
      company = user.company_users.first.company
      company2 = FactoryGirl.create(:company)
      FactoryGirl.create(:company_user, company: company2, user: user, role: FactoryGirl.create(:role, company: company2))
      get 'companies', auth_token: user.authentication_token, format: :json
      companies = JSON.parse(response.body)
      companies.should == [
        {'name' => company.name,  'id' => company.id },
        {'name' => company2.name, 'id' => company2.id}
      ]
      response.should be_success
    end
  end
end