require 'spec_helper'

describe UsersController do
  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe "GET 'edit'" do
    let(:user){ FactoryGirl.create(:user) }
    it "returns http success" do
      get 'edit', id: @user.to_param, format: :js
      response.should be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end
  end


  describe "PUT 'update'" do
    let(:user){ FactoryGirl.create(:user) }
    it "must update the user attributes" do
      put 'update', id: @user.to_param, user: {first_name: 'Juanito', last_name: 'Perez'}
      assigns(:user).should == @user
      response.should redirect_to(user_path(@user))
      @user.reload
      @user.first_name.should == 'Juanito'
      @user.last_name.should == 'Perez'
    end
  end

end
