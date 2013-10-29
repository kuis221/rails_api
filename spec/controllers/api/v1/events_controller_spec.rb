require 'spec_helper'

describe Api::V1::EventsController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  describe "GET 'index'", search: true do
    it "return a list of events" do
      campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place)
      events = FactoryGirl.create_list(:event, 3, company: company, campaign: campaign, place: place)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, format: :json
      response.should be_success
      events = JSON.parse(response.body)

      events.count.should == 3
      events.first.keys.should =~ ["id", "start_date", "start_time", "end_date", "end_time", "status", "event_status", "campaign", "place"]
    end

    it "return a list of events filtered by campaign id" do
      campaign = FactoryGirl.create(:campaign, company: company)
      other_campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place)
      events = FactoryGirl.create_list(:event, 3, company: company, campaign: campaign, place: place)
      other_events = FactoryGirl.create_list(:event, 3, company: company, campaign: other_campaign, place: place)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, campaign: [campaign.id], format: :json
      response.should be_success
      events = JSON.parse(response.body)

      events.count.should == 3
    end
  end

  describe "POST 'create'" do
    it "should assign current_user's company_id to the new event" do
      place = FactoryGirl.create(:place)
      lambda {
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, event: {campaign_id: 1, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm', place_id: place.id}, format: :json
      }.should change(Event, :count).by(1)
      assigns(:event).company_id.should == company.id
    end

    it "should create the event with the correct dates" do
      place = FactoryGirl.create(:place)
      lambda {
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, event: {campaign_id: 1, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/21/2020', end_time: '01:00pm', place_id: place.id}, format: :json
      }.should change(Event, :count).by(1)
      event = Event.last
      event.campaign_id.should == 1
      event.start_at.should == Time.zone.parse('2020/05/21 12:00pm')
      event.end_at.should == Time.zone.parse('2020/05/21 01:00pm')
      event.place_id.should == place.id
      event.promo_hours.should == 1
    end
  end

  describe "PUT 'update'" do
    let(:event){ FactoryGirl.create(:event, company: company) }
    it "must update the event attributes" do
      place = FactoryGirl.create(:place)
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, event: {campaign_id: 111, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm', place_id: place.id, active: 'false'}, format: :json
      assigns(:event).should == event
      response.should be_success
      event.reload
      event.campaign_id.should == 111
      event.start_at.should == Time.zone.parse('2020-05-21 12:00:00')
      event.end_at.should == Time.zone.parse('2020-05-22 13:00:00')
      event.place_id.should == place.id
      event.promo_hours.to_i.should == 25
      event.active.should == false
    end

    it "must update the event attributes" do
      place = FactoryGirl.create(:place)
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, partial: 'event_data', event: {campaign_id: FactoryGirl.create(:campaign, company: @company).to_param, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm', place_id: place.id}, format: :json
      assigns(:event).should == event
      response.should be_success
    end
  end
end