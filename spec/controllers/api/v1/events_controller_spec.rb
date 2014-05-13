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

    it "sencond page returns empty results" do
      campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place)
      events = FactoryGirl.create_list(:event, 3, company: company, campaign: campaign, place: place)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, page: 2, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result['results'].count.should == 0
      result['total'].should == 3
      result['page'].should == 2
      result['results'].should be_empty
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
    let(:campaign){ FactoryGirl.create(:campaign, company: company) }
    it "should assign current_user's company_id to the new event" do
      place = FactoryGirl.create(:place)
      lambda {
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, event: {campaign_id: campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm', place_id: place.id}, format: :json
      }.should change(Event, :count).by(1)
      assigns(:event).company_id.should == company.id
    end

    it "should create the event with the correct dates" do
      place = FactoryGirl.create(:place)
      lambda {
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, event: {campaign_id: campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/21/2020', end_time: '01:00pm', place_id: place.id}, format: :json
      }.should change(Event, :count).by(1)
      event = Event.last
      event.campaign_id.should == campaign.id
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
      new_campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place)
      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, event: {campaign_id: new_campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm', place_id: place.id}, format: :json
      assigns(:event).should == event
      response.should be_success
      event.reload
      event.campaign_id.should == new_campaign.id
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

      put 'update', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, event: {results_attributes: {"0" => {id: result.id.to_s, value: '987'}}}, format: :json
      result.reload
      result.value.should == 987
    end
  end


  describe "PUT 'submit'" do
    it "should submit event" do
      event = FactoryGirl.create(:event, active: true, company: @company)
      lambda {
        put 'submit', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
        response.should be_success
        event.reload
      }.should change(event, :submitted?).to(true)
    end

    it "should not allow to submit the event if the event data is not valid" do
      campaign = FactoryGirl.create(:campaign, company_id: company)
      field = FactoryGirl.create(:campaign_form_field, campaign: campaign, kpi: FactoryGirl.create(:kpi, company_id: 1), field_type: 'number', options: {required: true})
      event = FactoryGirl.create(:event, active: true, company: company, campaign: campaign)
      lambda {
        put 'submit', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
        response.response_code.should == 422
        event.reload
      }.should_not change(event, :submitted?).to(true)
    end
  end


  describe "PUT 'approve'" do
    it "should approve event" do
      event = FactoryGirl.create(:submitted_event, active: true, company: @company)
      lambda {
        put 'approve', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
        response.should be_success
        event.reload
      }.should change(event, :approved?).to(true)
    end
  end


  describe "PUT 'reject'" do
    it "should reject event" do
      event = FactoryGirl.create(:submitted_event, active: true, company: @company)
      lambda {
        put 'reject', auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, reason: 'blah blah blah', format: :json
        response.should be_success
        event.reload
      }.should change(event, :rejected?).to(true)
      event.reject_reason.should == 'blah blah blah'
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

      groups = JSON.parse(response.body)
      response.should be_success
      expect(groups.first["fields"].first).to include(
          'id' => result.id,
          'name' => '# of cats',
          'field_type' => 'number',
          'value' => 321
        )
      expect(groups.first['fields'].first.keys).to_not include('segments')
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
      groups = JSON.parse(response.body)
      expect(groups.first["fields"].first).to include(
          'id' => result.id,
          'name' => 'Are you tall?',
          'field_type' => 'count',
          'value' => segments.first.id,
          'description' => 'some description to show',
          'segments' => [
              {'id' => segments.first.id, 'text' => 'Yes', 'goal' => nil},
              {'id' => segments.last.id, 'text' => 'No', 'goal' => nil}
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
      groups = JSON.parse(response.body)
      expect(groups.first["fields"].first).to include(
          'name' => 'Age',
          'field_type' => 'percentage',
          'segments' => [
              {'id' => results.first.id, 'text' => 'Uno', 'value' => nil, 'goal' => nil},
              {'id' => results.last.id, 'text' => 'Dos', 'value' => nil, 'goal' => nil}
          ]
        )

      expect(groups.first['fields'].first.keys).to_not include('id', 'value')
    end
  end

  describe "GET 'team'" do
    let(:event) { FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company)) }
    it "return a list of users" do
      users = [
        FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Luis', last_name: 'Perez', email: "luis@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Field Ambassador', company: event.company)),
        FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Pedro', last_name: 'Guerra', email: "pedro@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Coach', company: event.company))
      ]
      event.users << users

      get :members, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      log_company_user = user.company_users.first
      result.should =~ [
        {"id"=>log_company_user.id, "first_name"=>log_company_user.first_name, "last_name"=>log_company_user.last_name, "full_name"=>log_company_user.full_name, "role_name"=>'Super Admin', "email"=>user.email, "phone_number"=>'(506) 22124578', "street_address"=>'Street Address 123', "unit_number"=>'Unit Number 456', "city"=>'Curridabat', "state"=>'SJ', "zip_code"=>"90210", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"},
        {"id"=>users.last.id, "first_name"=>"Pedro", "last_name"=>"Guerra", "full_name"=>"Pedro Guerra", "role_name"=>"Coach", "email"=>"pedro@gmail.com", "phone_number"=>"(506) 22124578", "street_address"=>"ABC 1", "unit_number"=>"#123 2nd floor", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"12345", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"},
        {"id"=>users.first.id, "first_name"=>"Luis", "last_name"=>"Perez", "full_name"=>"Luis Perez", "role_name"=>"Field Ambassador", "email"=>"luis@gmail.com", "phone_number"=>"(506) 22124578", "street_address"=>"ABC 1", "unit_number"=>"#123 2nd floor", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"12345", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"}
      ]
    end

    it "return a list of teams" do
      teams = [
        FactoryGirl.create(:team, name: 'Team C', description: 'team 3 description'),
        FactoryGirl.create(:team, name: 'Team A', description: 'team 1 description'),
        FactoryGirl.create(:team, name: 'Team B', description: 'team 2 description')
      ]
      event.teams << teams
      company_user = user.company_users.first
      get :members, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      company_user = user.company_users.first
      result.should =~ [
        {"id"=>teams.second.id, "name"=>"Team A", "description"=>"team 1 description", "type"=>"team"},
        {"id"=>teams.last.id, "name"=>"Team B", "description"=>"team 2 description", "type"=>"team"},
        {"id"=>teams.first.id, "name"=>"Team C", "description"=>"team 3 description", "type"=>"team"},
        {"id"=>company_user.id, "first_name"=>"Test", "last_name"=>"User", "full_name"=>"Test User", "role_name"=>"Super Admin", "email"=>user.email, "phone_number"=>"(506) 22124578", "street_address"=>"Street Address 123", "unit_number"=>"Unit Number 456", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"90210", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"}
      ]
    end

    describe "event with users and teams" do
      before do
        @users = [
          FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'A', last_name: 'User', email: "luis@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Field Ambassador', company: company), company: company),
          FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'User', last_name: '2', email: "pedro@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Coach', company: company), company: company)
        ]
        @teams = [
          FactoryGirl.create(:team, name: 'A team', description: 'team 1 description'),
          FactoryGirl.create(:team, name: 'Team 2', description: 'team 2 description')
        ]
        event.users << @users
        event.teams << @teams
      end

      it "return a mixed list of users and teams" do
        get :members, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
        response.should be_success
        result = JSON.parse(response.body)
        company_user = user.company_users.first
        result.should =~ [
          {"id"=>@teams.first.id, "name"=>"A team", "description"=>"team 1 description", "type"=>"team"},
          {"id"=>@users.first.id, "first_name"=>"A", "last_name"=>"User", "full_name"=>"A User", "role_name"=>"Field Ambassador", "email"=>"luis@gmail.com", "phone_number"=>"(506) 22124578", "street_address"=>"ABC 1", "unit_number"=>"#123 2nd floor", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"12345", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"},
          {"id"=>@teams.last.id, "name"=>"Team 2", "description"=>"team 2 description", "type"=>"team"},
          {"id"=>@users.last.id, "first_name"=>"User", "last_name"=>"2", "full_name"=>"User 2", "role_name"=>"Coach", "email"=>"pedro@gmail.com", "phone_number"=>"(506) 22124578", "street_address"=>"ABC 1", "unit_number"=>"#123 2nd floor", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"12345", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"},
          {"id"=>company_user.id, "first_name"=>"Test", "last_name"=>"User", "full_name"=>"Test User", "role_name"=>"Super Admin", "email"=>user.email, "phone_number"=>"(506) 22124578", "street_address"=>"Street Address 123", "unit_number"=>"Unit Number 456", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"90210", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"}
        ]
      end

      it "returns only the users" do
        get :members, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, type: 'user', format: :json
        response.should be_success
        result = JSON.parse(response.body)
        company_user = user.company_users.first
        result.should =~ [
          {"id"=>@users.first.id, "first_name"=>"A", "last_name"=>"User", "full_name"=>"A User", "role_name"=>"Field Ambassador", "email"=>"luis@gmail.com", "phone_number"=>"(506) 22124578", "street_address"=>"ABC 1", "unit_number"=>"#123 2nd floor", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"12345", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"},
          {"id"=>@users.last.id, "first_name"=>"User", "last_name"=>"2", "full_name"=>"User 2", "role_name"=>"Coach", "email"=>"pedro@gmail.com", "phone_number"=>"(506) 22124578", "street_address"=>"ABC 1", "unit_number"=>"#123 2nd floor", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"12345", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"},
          {"id"=>company_user.id, "first_name"=>"Test", "last_name"=>"User", "full_name"=>"Test User", "role_name"=>"Super Admin", "email"=>user.email, "phone_number"=>"(506) 22124578", "street_address"=>"Street Address 123", "unit_number"=>"Unit Number 456", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"90210", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"}
        ]
      end

      it "returns only the team" do
        get :members, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, type: 'team', format: :json
        response.should be_success
        result = JSON.parse(response.body)

        result.should == [
          {"id"=>@teams.first.id, "name"=>"A team", "description"=>"team 1 description", "type"=>"team"},
          {"id"=>@teams.last.id, "name"=>"Team 2", "description"=>"team 2 description", "type"=>"team"}
        ]
      end
    end
  end

  describe "GET 'contacts'" do
    let(:event) { FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company)) }
    it "return a list of contacts" do
      contacts = [
        FactoryGirl.create(:contact, first_name: 'Luis', last_name: 'Perez', email: "luis@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador'),
        FactoryGirl.create(:contact, first_name: 'Pedro', last_name: 'Guerra', email: "pedro@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Coach')
      ]
      FactoryGirl.create(:contact_event, event: event, contactable: contacts.first)
      FactoryGirl.create(:contact_event, event: event, contactable: contacts.last)

      get :contacts, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result.should =~ [
        {"id"=>contacts.first.id, "first_name"=>"Luis", "last_name"=>"Perez", "full_name"=>"Luis Perez", "title"=>"Field Ambassador", "email"=>"luis@gmail.com", "phone_number"=>"344-23333", "street1"=>"ABC", "street2"=>"1", "street_address"=>"ABC, 1", "city"=>"Hollywood", "state"=>"CA", "zip_code"=>"12345", "country"=>"United States","type"=>"contact"},
        {"id"=>contacts.last.id, "first_name"=>"Pedro", "last_name"=>"Guerra", "full_name"=>"Pedro Guerra", "title"=>"Coach", "email"=>"pedro@gmail.com", "phone_number"=>"344-23333", "street1"=>"ABC", "street2"=>"1", "street_address"=>"ABC, 1", "city"=>"Hollywood", "state"=>"CA", "zip_code"=>"12345", "country"=>"United States","type"=>"contact"}
      ]
    end

    it "users can also be added as contacts" do
      company_user = user.company_users.first
      FactoryGirl.create(:contact_event, event: event, contactable: company_user)

      get :contacts, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result.should =~ [
        {"id"=>company_user.id, "first_name"=>"Test", "last_name"=>"User", "full_name"=>"Test User", "role_name"=>"Super Admin", "email"=>user.email, "phone_number"=>"(506) 22124578", "street_address"=>"Street Address 123", "unit_number"=>"Unit Number 456", "city"=>"Curridabat", "state"=>"SJ", "zip_code"=>"90210", "time_zone"=>"Pacific Time (US & Canada)", "country"=>"Costa Rica", "type"=>"user"}
      ]
    end
  end

  describe "GET 'assignable_members'" do
    let(:event) { FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company)) }
    it "return a list of users that are not assined to the event" do
      users = [
        FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Luis', last_name: 'Perez', email: "luis@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Field Ambassador', company: company), company: company),
        FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Pedro', last_name: 'Guerra', email: "pedro@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Coach', company: company), company: company)
      ]

      event.users << user.company_users.first

      get :assignable_members, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result.should =~ [
        {"id"=>users.first.id.to_s, "name"=>"Luis Perez",   "description"=>"Field Ambassador", 'type' => 'user'},
        {"id"=>users.last.id.to_s,  "name"=>"Pedro Guerra", "description"=>"Coach", 'type' => 'user'}
      ]
    end

    it "returns users and teams mixed on the list" do
      teams = [
        FactoryGirl.create(:team, name: 'Z Team', description: 'team 3 description', company: company),
        FactoryGirl.create(:team, name: 'Team A', description: 'team 1 description', company: company),
        FactoryGirl.create(:team, name: 'Team B', description: 'team 2 description', company: company)
      ]
      company_user = user.company_users.first
      teams.each{|t| t.users << company_user}

      get :assignable_members, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result.should =~ [
        {"id"=>teams.second.id.to_s, "name"=>"Team A", "description"=>"team 1 description", 'type' => 'team'},
        {"id"=>teams.last.id.to_s, "name"=>"Team B", "description"=>"team 2 description", 'type' => 'team'},
        {"id"=>teams.first.id.to_s, "name"=>"Z Team", "description"=>"team 3 description", 'type' => 'team'}
      ]
    end
  end

  describe "POST 'add_member'" do
    let(:event) { FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company)) }

    it "should add a team to the event's team" do
      team = FactoryGirl.create(:team, company: company)
      expect {
        post :add_member, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, memberable_id: team.id, memberable_type: 'team', format: :json
      }.to change(Teaming, :count).by(1)
      event.teams.should == [team]

      response.should be_success
      result = JSON.parse(response.body)
      result.should == { 'success' => true, 'info' => "Member successfully added to event", 'data' => {} }
    end

    it "should add a user to the event's team" do
      company_user = FactoryGirl.create(:company_user, company_id: company.to_param)
      expect {
        post :add_member, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, memberable_id: company_user.id, memberable_type: 'user', format: :json
      }.to change(Membership, :count).by(2)
      event.users.should =~ [user.company_users.first, company_user]

      response.should be_success
      result = JSON.parse(response.body)
      result.should == { 'success' => true, 'info' => "Member successfully added to event", 'data' => {} }
    end
  end

  describe "DELETE 'delete_member'" do
    let(:event) { FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company)) }

    it "should remove a member (type = user) from the event" do
      member_to_delete = FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Test', last_name: 'User', email: "pedro@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Coach', company: company), company: company)
      another_member = FactoryGirl.create(:team, name: 'A team', description: 'team 1 description')
      event.users << member_to_delete
      event.teams << another_member

      expect {
        delete :delete_member, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, memberable_id: member_to_delete.id, memberable_type: 'user', format: :json
      }.to change(Membership, :count).by(-1)
      event.reload
      event.users.should == [user.company_users.first]
      event.teams.should == [another_member]

      response.should be_success
      response.response_code.should == 200
      result = JSON.parse(response.body)
      result.should == { 'success' => true, 'info' => "Member successfully deleted from event", 'data' => {} }
    end

    it "should remove a member (type = team) from the event" do
      member_to_delete = FactoryGirl.create(:team, name: 'A team', description: 'team 1 description')
      another_member = FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Test', last_name: 'User', email: "pedro@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Coach', company: company), company: company)
      event.users << another_member
      event.teams << member_to_delete

      expect {
        delete :delete_member, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, memberable_id: member_to_delete.id, memberable_type: 'team', format: :json
      }.to change(Teaming, :count).by(-1)
      event.reload
      event.users.should =~ [another_member, user.company_users.first]
      event.teams.should == []

      response.should be_success
      response.response_code.should == 200
      result = JSON.parse(response.body)
      result.should == { 'success' => true, 'info' => "Member successfully deleted from event", 'data' => {} }
    end

    it "return 404 if the member is not found" do
      member = FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Test', last_name: 'User', email: "pedro@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Coach', company: company), company: company)

      expect {
        delete :delete_member, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, memberable_id: member.id, memberable_type: 'user', format: :json
      }.to change(Membership, :count).by(1)
      event.reload
      event.users.should == [user.company_users.first]
      event.teams.should == []

      response.should_not be_success
      response.response_code.should == 404
      result = JSON.parse(response.body)
      result.should == { 'success' => false, 'info' => "Record not found", 'data' => {} }
    end
  end

  describe "GET 'assignable_contacts'", search: true do
    let(:event) { FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company)) }
    it "return a list of contacts that are not assined to the event" do
      contacts = [
        FactoryGirl.create(:contact, first_name: 'Luis', last_name: 'Perez', email: "luis@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador', company: company),
        FactoryGirl.create(:contact, first_name: 'Pedro', last_name: 'Guerra', email: "pedro@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Coach', company: company)
      ]

      associated_contact = FactoryGirl.create(:contact, first_name: 'Juan', last_name: 'Rodriguez', email: "juan@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador')
      FactoryGirl.create(:contact_event, event: event, contactable: associated_contact)   # this contact should not be returned on the list
      FactoryGirl.create(:contact_event, event: event, contactable: user.company_users.first) # Also associate the current user so it's not returned in the results

      Sunspot.commit

      get :assignable_contacts, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result.should =~ [
        {"id"=>contacts.first.id, "full_name"=>"Luis Perez", "title"=>"Field Ambassador", 'type' => 'contact'},
        {"id"=>contacts.last.id, "full_name"=>"Pedro Guerra", "title"=>"Coach", 'type' => 'contact'}
      ]
    end

    it "returns users and contacts mixed on the list" do
      contacts = [
        FactoryGirl.create(:contact, first_name: 'Luis', last_name: 'Perez', email: "luis@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador', company: company),
        FactoryGirl.create(:contact, first_name: 'Pedro', last_name: 'Guerra', email: "pedro@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Coach', company: company)
      ]
      company_user = user.company_users.first
      Sunspot.commit

      get :assignable_contacts, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result.should =~ [
        {"id"=>contacts.first.id, "full_name"=>"Luis Perez", "title"=>"Field Ambassador", 'type' => 'contact'},
        {"id"=>contacts.last.id, "full_name"=>"Pedro Guerra", "title"=>"Coach", 'type' => 'contact'},
        {"id"=>company_user.id, "full_name"=>company_user.full_name, "title"=>company_user.role_name, 'type' => 'user'},
      ]
    end

    it "returns results match a search term" do
      contacts = [
        FactoryGirl.create(:contact, first_name: 'Luis', last_name: 'Perez', email: "luis@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador', company: company),
        FactoryGirl.create(:contact, first_name: 'Pedro', last_name: 'Guerra', email: "pedro@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Coach', company: company)
      ]
      company_user = user.company_users.first
      Sunspot.commit

      get :assignable_contacts, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, term: 'luis', format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result.should =~ [
        {"id"=>contacts.first.id, "full_name"=>"Luis Perez", "title"=>"Field Ambassador", 'type' => 'contact'}
      ]
    end
  end

  describe "POST 'add_contact'" do
    let(:event) { FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company)) }

    it "should add a contact to the event as a contact" do
      contact = FactoryGirl.create(:contact, first_name: 'Luis', last_name: 'Perez', email: "luis@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador', company: company)
      expect {
        post :add_contact, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, contactable_id: contact.id, contactable_type: 'contact', format: :json
      }.to change(ContactEvent, :count).by(1)
      event.contacts.should == [contact]

      response.should be_success
      result = JSON.parse(response.body)
      result.should == { 'success' => true, 'info' => "Contact successfully added to event", 'data' => {} }
    end

    it "should add a user to the event as a contact" do
      company_user = user.company_users.first
      expect {
        post :add_contact, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, contactable_id: company_user.id, contactable_type: 'user', format: :json
      }.to change(ContactEvent, :count).by(1)
      event.contacts.should == [company_user]

      response.should be_success
      result = JSON.parse(response.body)
      result.should == { 'success' => true, 'info' => "Contact successfully added to event", 'data' => {} }
    end
  end

  describe "DELETE 'delete_contact'" do
    let(:event) { FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company)) }

    it "should remove a contact (type = user) from the event" do
      contact_to_delete = FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Pedro', last_name: 'Guerra', email: "pedro@gmail.com", street_address: 'ABC 1', unit_number: '#123 2nd floor', zip_code: 12345), role: FactoryGirl.create(:role, name: 'Coach', company: event.company))
      another_contact = FactoryGirl.create(:contact, first_name: 'Juan', last_name: 'Rodriguez', email: "juan@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador')
      FactoryGirl.create(:contact_event, event: event, contactable: contact_to_delete)
      FactoryGirl.create(:contact_event, event: event, contactable: another_contact)

      expect {
        delete :delete_contact, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, contactable_id: contact_to_delete.id, contactable_type: 'user', format: :json
      }.to change(ContactEvent, :count).by(-1)
      event.contacts.should == [another_contact]

      response.should be_success
      response.response_code.should == 200
      result = JSON.parse(response.body)
      result.should == { 'success' => true, 'info' => "Contact successfully deleted from event", 'data' => {} }
    end

    it "should remove a contact (type = contact) from the event" do
      contact_to_delete = FactoryGirl.create(:contact, first_name: 'Juan', last_name: 'Rodriguez', email: "juan@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador')
      another_contact = user.company_users.first
      FactoryGirl.create(:contact_event, event: event, contactable: contact_to_delete)
      FactoryGirl.create(:contact_event, event: event, contactable: another_contact)

      expect {
        delete :delete_contact, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, contactable_id: contact_to_delete.id, contactable_type: 'contact', format: :json
      }.to change(ContactEvent, :count).by(-1)
      event.contacts.should == [another_contact]

      response.should be_success
      response.response_code.should == 200
      result = JSON.parse(response.body)
      result.should == { 'success' => true, 'info' => "Contact successfully deleted from event", 'data' => {} }
    end

    it "return 404 if the contact is not found" do
      contact = FactoryGirl.create(:contact, first_name: 'Luis', last_name: 'Perez', email: "luis@gmail.com", street1: 'ABC', street2: '1', zip_code: 12345, title: 'Field Ambassador', company: company)

      expect {
        delete :delete_contact, auth_token: user.authentication_token, company_id: company.to_param, id: event.to_param, contactable_id: contact.id, contactable_type: 'contact', format: :json
      }.to change(ContactEvent, :count).by(0)

      event.contacts.should == []

      response.should_not be_success
      response.response_code.should == 404
      result = JSON.parse(response.body)
      result.should == { 'success' => false, 'info' => "Record not found", 'data' => {} }
    end
  end

  describe "GET 'autocomplete'", search: true do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: '', format: :json
      response.should be_success

      buckets = JSON.parse(response.body)
      buckets.map{|b| b['label']}.should == ['Campaigns', 'Brands', 'Places', 'People']
    end

    it "should return the users in the People Bucket" do
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'gu', format: :json
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end

    it "should return the teams in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Spurs', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'sp', format: :json
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Sp</i>urs", "value" => team.id.to_s, "type"=>"team"}]
    end

    it "should return the teams and users in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Valladolid', company_id: company.id)
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'va', format: :json
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Va</i>lladolid", "value"=>team.id.to_s, "type"=>"team"}, {"label"=>"Guillermo <i>Va</i>rgas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end

    it "should return the campaigns in the Campaigns Bucket" do
      campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'cac', format: :json
      response.should be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
      campaigns_bucket['value'].should == [{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}]
    end

    it "should return the brands in the Brands Bucket" do
      brand = FactoryGirl.create(:brand, name: 'Cacique', company_id: company.to_param)
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'cac', format: :json
      response.should be_success

      buckets = JSON.parse(response.body)
      brands_bucket = buckets.select{|b| b['label'] == 'Brands'}.first
      brands_bucket['value'].should == [{"label"=>"<i>Cac</i>ique", "value"=>brand.id.to_s, "type"=>"brand"}]
    end

    it "should return the venues in the Places Bucket" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      venue = FactoryGirl.create(:venue, company_id: company.id, place: FactoryGirl.create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'mot', format: :json
      response.should be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
      places_bucket['value'].should == [{"label"=>"<i>Mot</i>el Paraiso", "value"=>venue.id.to_s, "type"=>"venue"}]
    end
  end
end