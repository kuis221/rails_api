require 'spec_helper'

describe "Activities" do
  before(:each) do
    @current_user = FactoryGirl.create(:user)
    post_via_redirect user_session_url('user[email]' => @current_user.email, 'user[password]' => @current_user.password)
  end
  describe "GET /activities" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get activities_path
      response.status.should be(200)
    end
  end
end
