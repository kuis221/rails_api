require 'spec_helper'

describe "Events" do

  before do
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    sign_in @user
  end

  describe "/events" do
    it "GET index should be ok" do
      get events_path
      response.status.should be(200)
    end

    it "GET show should be ok" do
      event = FactoryGirl.create(:event)
      get event_path(event)
      response.status.should be(200)
    end

  end

end