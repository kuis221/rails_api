require 'spec_helper'

describe Devise::SessionsController do
  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end
  describe  "#create" do
    describe "an active user" do
      before(:each) do
        @user = FactoryGirl.create(:user, password: 'Test12345!', password_confirmation: 'Test12345!', company_id: 1)
      end
      it "should be able to login" do
        lambda {
          post "create", user: {email: @user.email, password: @user.password}
          @user.reload
        }.should change(@user, :last_sign_in_at)
      end
    end

    describe "an deactivated user" do
      it "should not be able to login" do
        @user = FactoryGirl.create(:user, password: 'Test12345!', password_confirmation: 'Test12345!', company_id: 1, active: false)
        lambda {
          post "create", user: {email: @user.email, password: @user.password}
          @user.reload
        }.should_not change(@user, :last_sign_in_at)
        flash[:alert].should == 'Your account was not activated yet.'
      end
    end
  end
end