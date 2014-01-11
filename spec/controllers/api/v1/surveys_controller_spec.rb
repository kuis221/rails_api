require 'spec_helper'

describe Api::V1::SurveysController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { FactoryGirl.create(:campaign, company: company, name: 'Test Campaign FY01') }
  let(:place) { FactoryGirl.create(:place) }

  describe "GET 'index'" do
    it "should return failure for invalid authorization token" do
      get :index, company_id: company.to_param, auth_token: 'XXXXXXXXXXXXXXXX', event_id: 100, format: :json
      response.response_code.should == 401
      result = JSON.parse(response.body)
      result['success'].should == false
      result['info'].should == 'Invalid auth token'
      result['data'].should be_empty
    end

    it "returns the list of surveys for the event" do
      event = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)
      survey1 = FactoryGirl.create(:survey, event: event)
      survey2 = FactoryGirl.create(:survey, event: event)
      event.save
      Sunspot.commit

      get :index, company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result.count.should == 2
      expect(result.first).to include({'id' => survey1.id})
      expect(result.last).to  include({'id' => survey2.id})
    end
  end

end