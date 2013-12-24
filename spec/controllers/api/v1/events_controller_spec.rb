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
      result = JSON.parse(response.body)

      result['results'].count.should == 3
      result['total'].should == 3
      result['page'].should == 1
      result['results'].first.keys.should =~ ["id", "start_date", "start_time", "end_date", "end_time", "status", "event_status", "campaign", "place"]
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
      result = JSON.parse(response.body)

      result['results'].count.should == 3
    end

    it "return the facets for the search" do
      campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place)
      FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)
      FactoryGirl.create(:rejected_event, company: company, campaign: campaign, place: place)
      FactoryGirl.create(:submitted_event, company: company, campaign: campaign, place: place)
      FactoryGirl.create(:late_event, company: company, campaign: campaign, place: place)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result['results'].count.should == 4
      result['facets'].map{|f| f['label'] }.should =~ ["Campaigns", "Brands", "Areas", "People", "Active State", "Event Status"]

      result['facets'].detect{|f| f['label'] == 'Event Status' }['items'].map{|i| [i['label'], i['count']]}.should =~ [["Late", 1], ["Due", 0], ["Submitted", 1], ["Rejected", 1], ["Approved", 1]]
    end

    it "should not include the facets when the page is greater than 1" do
      get :index, auth_token: user.authentication_token, company_id: company.to_param, page: 2, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result['results'].should == []
      result['facets'].should be_nil
      result['page'].should == 2
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
    let(:campaign){ FactoryGirl.create(:campaign, company: company) }
    let(:event){ FactoryGirl.create(:event, company: company, campaign: campaign) }
    it "must update the event attributes" do
      place = FactoryGirl.create(:place)
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, event: {campaign_id: 111, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm', place_id: place.id}, format: :json
      assigns(:event).should == event
      response.should be_success
      event.reload
      event.campaign_id.should == 111
      event.start_at.should == Time.zone.parse('2020-05-21 12:00:00')
      event.end_at.should == Time.zone.parse('2020-05-22 13:00:00')
      event.place_id.should == place.id
      event.promo_hours.to_i.should == 25
    end

    it "must deactivate the event" do
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, event: {active: 'false'}, format: :json
      assigns(:event).should == event
      response.should be_success
      event.reload
      event.active.should == false
    end

    it "must update the event attributes" do
      place = FactoryGirl.create(:place)
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, partial: 'event_data', event: {campaign_id: FactoryGirl.create(:campaign, company: @company).to_param, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm', place_id: place.id}, format: :json
      assigns(:event).should == event
      response.should be_success
    end

    it 'must update the event results' do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      result = event.result_for_kpi(Kpi.impressions)
      result.value = 321
      event.save

      put 'update',  auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, event: {results_attributes: [{id: result.id, value: '987'}]}
      result.reload
      result.value.should == 987
    end
  end

  describe "GET 'results'" do
    let(:campaign){ FactoryGirl.create(:campaign, company: company) }
    let(:event){ FactoryGirl.create(:event, company: company, campaign: campaign) }

    it "should return an empty array if the campaign doesn't have any fields" do
      get 'results', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      fields = JSON.parse(response.body)
      response.should be_success
      fields.should == []
    end

    it "should return the stored values within the fields" do
      kpi = FactoryGirl.create(:kpi, name: '# of cats', kpi_type: 'number')
      campaign.add_kpi kpi
      result = event.result_for_kpi(kpi)
      result.value = 321
      event.save
      get 'results', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json

      fields = JSON.parse(response.body)
      response.should be_success
      expect(fields.first).to include(
          'id' => result.id,
          'name' => '# of cats',
          'field_type' => 'number',
          'value' => 321
        )
      expect(fields.first.keys).to_not include('segments')
    end

    it "should return the segments for count fields" do
      kpi = FactoryGirl.create(:kpi, name: 'Are you tall?', kpi_type: 'count', description: 'some description to show',
          kpis_segments: [
            FactoryGirl.create(:kpis_segment, text: 'Yes'), FactoryGirl.create(:kpis_segment, text: 'No')
          ]
      )
      campaign.add_kpi kpi
      segments = kpi.kpis_segments
      result = event.result_for_kpi(kpi)
      result.value = segments.first.id
      event.save

      get 'results', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      fields = JSON.parse(response.body)
      expect(fields.first).to include(
          'id' => result.id,
          'name' => 'Are you tall?',
          'field_type' => 'count',
          'value' => segments.first.id,
          'description' => 'some description to show',
          'segments' => [
              {'id' => segments.first.id, 'text' => 'Yes'},
              {'id' => segments.last.id, 'text' => 'No'}
          ]
        )
    end

    it "should return the percentage fields as one single field" do
      kpi = FactoryGirl.create(:kpi, name: 'Age', kpi_type: 'percentage',
          kpis_segments: [
            FactoryGirl.create(:kpis_segment, text: 'Uno'), FactoryGirl.create(:kpis_segment, text: 'Dos')
          ]
      )
      campaign.add_kpi kpi
      results = event.result_for_kpi(kpi)
      event.save

      get 'results', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      fields = JSON.parse(response.body)
      expect(fields.first).to include(
          'name' => 'Age',
          'field_type' => 'percentage',
          'segments' => [
              {'id' => results.first.id, 'text' => 'Uno', 'value' => nil},
              {'id' => results.last.id, 'text' => 'Dos', 'value' => nil}
          ]
        )

      expect(fields.first.keys).to_not include('id', 'value')
    end
  end
end