require 'spec_helper'

describe Admin::KpisController do
  before do
    @user = FactoryGirl.create(:admin_user)
    sign_in @user
  end

  let(:kpi) { FactoryGirl.create(:kpi) }

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      response.should be_success
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      get 'show', id: kpi.to_param
      response.should be_success
      assigns(:kpi).should == kpi
    end
  end
end