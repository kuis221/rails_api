require 'rails_helper'

describe EventsController, :type => :controller do
  describe "as registered user" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.companies.first
      @company_user = @user.current_company_user
    end

    after do
      Timecop.return
    end

    describe "GET 'new'" do
      it "returns http success" do
        xhr :get, 'new', format: :js
        expect(response).to be_success
        expect(response).to render_template('new')
        expect(response).to render_template('_form')
      end
    end

    describe "GET 'edit'" do
      let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company)) }
      it "returns http success" do
        xhr :get, 'edit', id: event.to_param, format: :js
        expect(response).to be_success
      end
    end

    describe "GET 'edit_data'" do
      let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company)) }
      it "returns http success" do
        event.build_event_data.save
        xhr :get, 'edit_data', id: event.to_param, format: :js
        expect(response).to be_success
        expect(response).to render_template('edit_data')
      end
    end

    describe "GET 'edit_surveys'" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "returns http success" do
        xhr :get, 'edit_surveys', id: event.to_param, format: :js
        expect(response).to be_success
        expect(response).to render_template('edit_surveys')
        expect(response).to render_template('_surveys')
      end
    end

    describe "GET 'show'" do
      describe "for an event in the future" do
        let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company), start_date: 1.week.from_now.to_s(:slashes), end_date: 1.week.from_now.to_s(:slashes)) }

        it "renders the correct templates" do
          get 'show', id: event.to_param
          expect(response).to be_success
          expect(response).to render_template('show')
          expect(response).not_to render_template('show_results')
          expect(response).not_to render_template('edit_results')
        end
      end

      describe "for an event in the past" do
        let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company), start_date: 1.day.ago.to_s(:slashes), end_date: 1.day.ago.to_s(:slashes)) }

        describe "when no data have been entered" do
          it "renders the correct templates" do
            Kpi.create_global_kpis
            event.campaign.assign_all_global_kpis
            get 'show', id: event.to_param
            expect(response).to be_success
            expect(response).to render_template('show')
            expect(response).to render_template('_edit_results')
            expect(response).to render_template('_surveys')
            expect(response).to render_template('_comments')
            expect(response).to render_template('_photos')
            expect(response).to render_template('_expenses')
            expect(response).not_to render_template('_show_results')
          end
        end
      end
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        expect(response).to be_success
      end

      describe "calendar_highlights" do
        it "loads the highligths for the calendar" do
          FactoryGirl.create(:event, company: @company, start_date: '01/23/2013', end_date: '01/24/2013')
          FactoryGirl.create(:event, company: @company, start_date: '02/15/2013', end_date: '02/15/2013')
          get 'index'
          expect(response).to be_success
          expect(assigns(:calendar_highlights)).to eq({ 2013 => { 1 => { 23 => 1, 24 => 1 }, 2 => { 15 => 1 } } })
        end
      end

      it "queue the job for export the list" do
        expect{
          xhr :get, :index, format: :xls
        }.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
      end
    end

    describe "GET 'list_export'", search: true do
      let(:campaign) { FactoryGirl.create(:campaign, company: @company, name: 'Test Campaign FY01') }
      it "should return an empty book with the correct headers" do
        expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
        spreadsheet_from_last_export do |doc|
          rows = doc.elements.to_a('//Row')
          expect(rows.count).to eql 1
          expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to eql [
            "CAMPAIGN NAME", "AREA", "START", "END", "VENUE NAME", "ADDRESS", "CITY", "STATE", "ZIP",
            "ACTIVE STATE", "EVENT STATUS", "TEAM MEMBERS","URL"]
        end
      end

      it "should include the event results" do
        place = FactoryGirl.create(:place, name: 'Bar Prueba', city: 'Los Angeles', state: 'California', country: 'US')
        event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign, place: place)
        team = FactoryGirl.create(:team, company: @company, name: "zteam")
        event.teams << team
        event.users << @company_user
        Sunspot.commit

        expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
        spreadsheet_from_last_export do |doc|
          rows = doc.elements.to_a('//Row')
          expect(rows.count).to eql 2
          expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to eql [
            "Test Campaign FY01", nil, "2019-01-23T10:00", "2019-01-23T12:00",
            "Bar Prueba", "Bar Prueba, Los Angeles, California, 12345", "Los Angeles", "California",
            "12345", "Active", "Approved", "Test User, zteam", "http://localhost:5100/events/#{event.id}" ]
        end
      end
    end

    describe "GET 'new'" do
      it "initializes the event with the correct date" do
        Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 13)) do
          xhr :get, 'new', format: :js
          expect(response).to be_success
          expect(assigns(:event).start_date).to eq(Time.zone.local(2013, 07, 26, 12, 15).to_s(:slashes))
          expect(assigns(:event).start_time).to eq(Time.zone.local(2013, 07, 26, 12, 15).to_s(:time_only))
          expect(assigns(:event).end_date).to eq(Time.zone.local(2013, 07, 26, 13, 15).to_s(:slashes))
          expect(assigns(:event).end_time).to eq(Time.zone.local(2013, 07, 26, 13, 15).to_s(:time_only))
        end
      end

      it "always choose the hour in the future" do
        Timecop.freeze(Time.zone.local(2013, 07, 26, 12, 01)) do
          xhr :get, 'new', format: :js
          expect(response).to be_success
          expect(assigns(:event).start_date).to eq(Time.zone.local(2013, 07, 26, 12, 15).to_s(:slashes))
          expect(assigns(:event).start_time).to eq(Time.zone.local(2013, 07, 26, 12, 15).to_s(:time_only))
          expect(assigns(:event).end_date).to eq(Time.zone.local(2013, 07, 26, 13, 15).to_s(:slashes))
          expect(assigns(:event).end_time).to eq(Time.zone.local(2013, 07, 26, 13, 15).to_s(:time_only))
        end
      end

      it "a event that ends on the next day" do
        Timecop.freeze(Time.zone.local(2013, 07, 26, 23, 01)) do
          xhr :get, 'new', format: :js
          expect(response).to be_success
          expect(assigns(:event).start_date).to eq(Time.zone.local(2013, 07, 26, 23, 15).to_s(:slashes))
          expect(assigns(:event).start_time).to eq(Time.zone.local(2013, 07, 26, 23, 15).to_s(:time_only))
          expect(assigns(:event).end_date).to eq(Time.zone.local(2013, 07, 27, 0, 15).to_s(:slashes))
          expect(assigns(:event).end_time).to eq(Time.zone.local(2013, 07, 27, 0, 15).to_s(:time_only))
        end
      end
    end

    describe "GET 'items'" do
      it "returns http success" do
        get 'items'
        expect(response).to be_success
      end
    end

    describe "GET 'tasks'" do
      let(:event) { FactoryGirl.create(:event, company: @company) }
      it "returns http success" do
        get 'tasks', id: event.to_param
        expect(response).to be_success
        expect(response).to render_template(:tasks)
        expect(response).to render_template('_tasks_counters')
      end
    end

    describe "POST 'create'" do
      let(:campaign){ FactoryGirl.create(:campaign, company: @company) }
      it "should not render form_dialog if no errors" do
        expect {
          xhr :post, 'create', event: {campaign_id: campaign.id, start_date: '05/23/2020', start_time: '12:00pm', end_date: '05/22/2021', end_time: '01:00pm'}, format: :js
        }.to change(Event, :count).by(1)
        expect(response).to be_success
        expect(response).to render_template(:create)
        expect(response).not_to render_template('_form_dialog')
      end

      it "should render the form_dialog template if errors" do
        expect {
          xhr :post, 'create', event: {campaign_id: 'XX'}, format: :js
        }.not_to change(Event, :count)
        expect(response).to render_template(:create)
        expect(response).to render_template('_form_dialog')
        assigns(:event).errors.count > 0
      end

      it "should assign current_user's company_id to the new event" do
        expect {
          xhr :post, 'create', event: {campaign_id: campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        }.to change(Event, :count).by(1)
        expect(assigns(:event).company_id).to eq(@company.id)
      end

      it "should assign users to the new event" do
        with_resque do
          @company_user.update_attributes(
            notifications_settings: ['new_event_team_sms', 'new_event_team_email'],
            user_attributes: {phone_number_verified: true} )
          expect(UserMailer).to receive(:notification).with(@company_user.id, "Added to Event", /You have a new event http:\/\/localhost:5100\/events\/[0-9]+/).and_return(double(deliver: true))
          expect {
            expect {
              post 'create', event: {
                campaign_id: campaign.id, team_members: ["company_user:#{@company_user.id}"],
                start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020',
                end_time: '01:00pm'}, format: :js
            }.to change(Event, :count).by(1)
          }.to change(Membership, :count).by(1)
          expect(assigns(:event).users.last.user.id).to eq(@user.id)
          open_last_text_message_for @user.phone_number
          expect(current_text_message).to have_body "You have a new event http://localhost:5100/events/#{Event.last.id}"
        end
      end

      it "should create the event with the correct dates" do
        expect {
          xhr :post, 'create', event: {campaign_id: campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/21/2020', end_time: '01:00pm'}, format: :js
        }.to change(Event, :count).by(1)
        event = Event.last
        expect(event.start_at).to eq(Time.zone.parse('2020/05/21 12:00pm'))
        expect(event.end_at).to eq(Time.zone.parse('2020/05/21 01:00pm'))
        expect(event.promo_hours).to eq(1)
      end

      it "should create the event with the given event team" do
        user = FactoryGirl.create(:company_user, company: @company)
        team = FactoryGirl.create(:team, company: @company)
        expect {
          post 'create', event: {
              campaign_id: campaign.id, team_members: ["company_user:#{user.id}", "team:#{team.id}"],
              start_date: '05/21/2020', start_time: '12:00pm', description: 'some description',
              end_date: '05/21/2020', end_time: '01:00pm'}, format: :js
        }.to change(Event, :count).by(1)
        event = Event.last
        expect(event.start_at).to eq(Time.zone.parse('2020/05/21 12:00pm'))
        expect(event.end_at).to eq(Time.zone.parse('2020/05/21 01:00pm'))
        expect(event.description).to eq('some description')
        expect(event.promo_hours).to eq(1)
        expect(event.users.to_a).to eql [user]
        expect(event.teams.to_a).to eql [team]
      end
    end

    describe "PUT 'update'" do
      let(:campaign){ FactoryGirl.create(:campaign, company: @company) }
      let(:event){ FactoryGirl.create(:event, company: @company, campaign: campaign) }
      it "must update the event attributes" do
        new_campaign = FactoryGirl.create(:campaign, company: @company)
        xhr :put, 'update', id: event.to_param, event: {campaign_id: new_campaign.id, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        expect(assigns(:event)).to eq(event)
        expect(response).to be_success
        event.reload
        expect(event.campaign_id).to eq(new_campaign.id)
        expect(event.start_at).to eq(Time.zone.parse('2020-05-21 12:00:00'))
        expect(event.end_at).to eq(Time.zone.parse('2020-05-22 13:00:00'))
      end

      it "must update the event attributes" do
        xhr :put, 'update', id: event.to_param, partial: 'event_data', event: {campaign_id: FactoryGirl.create(:campaign, company: @company).to_param, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        expect(assigns(:event)).to eq(event)
        expect(response).to be_success
        expect(response).to render_template('_results_event_data')
      end

      it "should update the event data for a event without data" do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis
        expect {
          put 'update', id: event.to_param,
            event: {
              summary: 'A summary of the events',
              results_attributes: {
                '0' => {form_field_id: campaign.form_field_for_kpi(Kpi.impressions), kpi_id: Kpi.impressions.id, kpis_segment_id: nil, value: "100"},
                '1' => {form_field_id: campaign.form_field_for_kpi(Kpi.interactions), kpi_id: Kpi.interactions.id, kpis_segment_id: nil, value: "200"}
              }
            }
        }.to change(FormFieldResult, :count).by(2)
        event.reload
        expect(event.summary).to eq('A summary of the events')
        expect(event.result_for_kpi(Kpi.impressions).value).to eq('100')
        expect(event.result_for_kpi(Kpi.interactions).value).to eq('200')
      end


      it "should update the event data for a event that already have results" do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis

        impressions = event.result_for_kpi(Kpi.impressions)
        interactions = event.result_for_kpi(Kpi.interactions)
        expect {
          event.result_for_kpi(Kpi.impressions).value = '100'
          event.result_for_kpi(Kpi.interactions).value = '200'
          event.save
        }.to change(FormFieldResult, :count).by(2)

        expect {
          put 'update', id: event.to_param,
            event: {
              summary: 'A summary of the events',
              results_attributes: {
                '0' => {form_field_id: campaign.form_field_for_kpi(Kpi.impressions), kpi_id: Kpi.impressions.id, kpis_segment_id: nil, value: "1111", id: impressions.id},
                '1' => {form_field_id: campaign.form_field_for_kpi(Kpi.interactions), kpi_id: Kpi.interactions.id, kpis_segment_id: nil, value: "2222", id: interactions.id}
              }
            }
        }.to_not change(FormFieldResult, :count)
        event.reload
        expect(event.summary).to eq('A summary of the events')
        expect(event.result_for_kpi(Kpi.impressions).value).to eq('1111')
        expect(event.result_for_kpi(Kpi.interactions).value).to eq('2222')
      end
    end

    describe "DELETE 'delete_member' with a user" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "should remove the team member from the event" do
        event.users << @company_user
        expect{
          delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js
          expect(response).to be_success
          expect(assigns(:event)).to eq(event)
          event.reload
        }.to change(event.users, :count).by(-1)
      end

      it "should unassign any tasks assigned the user" do
        event.users << @company_user
        other_user = FactoryGirl.create(:company_user, company_id: 1)
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user: other_user)
        delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js

        user_tasks.each{|t| expect(t.reload.company_user_id).to be_nil }
        other_tasks.each{|t| expect(t.reload.company_user_id).not_to be_nil }
      end

      it "should not raise error if the user doesn't belongs to the event" do
        delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js
        event.reload
        expect(response).to be_success
        expect(assigns(:event)).to eq(event)
      end
    end

    describe "DELETE 'delete_member' with a team" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      let(:team){ FactoryGirl.create(:team, company: @company) }
      it "should remove the team from the event" do
        event.teams << team
        expect{
          delete 'delete_member', id: event.id, team_id: team.id, format: :js
          expect(response).to be_success
          expect(assigns(:event)).to eq(event)
          event.reload
        }.to change(event.teams, :count).by(-1)
      end

      it "should unassign any tasks assigned the team users" do
        another_user = FactoryGirl.create(:company_user, company: @company)
        team.users << another_user
        event.teams << team
        other_user = FactoryGirl.create(:company_user, company_id: 1)
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: another_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user: other_user)
        delete 'delete_member', id: event.id, team_id: team.id, format: :js
        event.reload
        user_tasks.each{|t| expect(t.reload.company_user_id).to be_nil }
        other_tasks.each{|t| expect(t.reload.company_user_id).not_to be_nil }

      end

      it "should not unassign any tasks assigned the team users if the user is directly assigned to the event" do
        team.users << @company_user
        event.teams << team
        event.users << @company_user
        other_user = FactoryGirl.create(:company_user, company: @company)
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user: other_user)
        delete 'delete_member', id: event.id, team_id: team.id, format: :js

        user_tasks.each{|t| expect(t.reload.company_user_id).to eq(@company_user.id) }
        other_tasks.each{|t| expect(t.reload.company_user_id).not_to be_nil }
      end

      it "should not raise error if the team doesn't belongs to the event" do
        delete 'delete_member', id: event.id, team_id: team.id, format: :js
        event.reload
        expect(response).to be_success
        expect(assigns(:event)).to eq(event)
      end
    end

    describe "GET 'new_member" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it 'should load all the company\'s users into @users' do
        FactoryGirl.create(:user, company_id: @company.id+1)
        another_user = FactoryGirl.create(:company_user, company_id: @company.id,role_id: @company_user.role_id)
        xhr :get, 'new_member', id: event.id, format: :js
        event.reload
        expect(response).to be_success
        expect(assigns(:event)).to eq(event)
        expect(assigns(:staff)).to match_array [
          {'id' => @company_user.id.to_s, 'name' => @company_user.full_name, 'description' => 'Super Admin', 'type' => 'user'},
          {'id' => another_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user'}
        ]
      end

      it 'should not load the users that are already assigned to the event' do
        another_user = FactoryGirl.create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
        event.users << @company_user
        xhr :get, 'new_member', id: event.id, format: :js
        expect(response).to be_success
        expect(assigns(:event)).to eq(event)
        expect(assigns(:staff).to_a).to eq([{'id' => another_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user'}])
      end

      it 'should load teams with active users' do
        event.users << @company_user
        @company_user.user.update_attributes(first_name: 'CDE', last_name: 'FGH')
        team = FactoryGirl.create(:team, name: 'ABC', description: 'A sample team', company_id: @company.id)
        other_user = FactoryGirl.create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
        team.users << other_user
        xhr :get, 'new_member', id: event.id, format: :js
        expect(assigns(:assignable_teams)).to eq([team])
        expect(assigns(:staff).to_a).to eq([
          {'id' => team.id.to_s, 'name' => 'ABC', 'description' => 'A sample team', 'type' => 'team'},
          {'id' => other_user.id.to_s, 'name' => 'Test User', 'description' => 'Super Admin', 'type' => 'user'}
        ])
      end
    end

    describe "POST 'add_members" do
      let(:place){ FactoryGirl.create(:place) }
      let(:event){ FactoryGirl.create(:event, company: @company, place: place) }

      it 'should assign the user to the event and create a notification for the new member' do
        other_user = FactoryGirl.create(:company_user, company_id: @company.id)
        other_user.places << place
        expect {
          expect {
            xhr :post, 'add_members', id: event.id, member_id: other_user.to_param, format: :js
            expect(response).to be_success
            expect(assigns(:event)).to eq(event)
            event.reload
          }.to change(event.users, :count).by(1)
        }.to change(other_user.notifications, :count).by(1)
        expect(event.users).to match_array([other_user])
        other_user.reload
        notification = other_user.notifications.last
        expect(notification.company_user_id).to eq(other_user.id)
        expect(notification.message).to eq('new_event')
        expect(notification.path).to eq(event_path(event))
      end

      it 'should assign all the team to the event and create a notification for team members' do
        team = FactoryGirl.create(:team, company_id: @company.id)
        other_user = FactoryGirl.create(:company_user, company_id: @company.id)
        other_user.places << place
        team.users << other_user
        expect {
          expect {
            xhr :post, 'add_members', id: event.id, team_id: team.to_param, format: :js
            expect(response).to be_success
            expect(assigns(:event)).to eq(event)
            event.reload
          }.to change(event.teams, :count).by(1)
        }.to change(other_user.notifications, :count).by(1)
        expect(event.teams).to eq([team])
        other_user.reload
        notification = other_user.notifications.last
        expect(notification.company_user_id).to eq(other_user.id)
        expect(notification.message).to eq('new_team_event')
        expect(notification.path).to eq(event_path(event))
      end

      it 'should not assign users to the event if they are already part of the event' do
        event.users << @company_user
        expect {
          xhr :post, 'add_members', id: event.id, member_id: @company_user.to_param, format: :js
          expect(response).to be_success
          expect(assigns(:event)).to eq(event)
          event.reload
        }.not_to change(event.users, :count)
      end

      it 'should not assign teams to the event if they are already part of the event' do
        team = FactoryGirl.create(:team, company_id: @company.id)
        event.teams << team
        expect {
          xhr :post, 'add_members', id: event.id, team_id: team.to_param, format: :js
          expect(response).to be_success
          expect(assigns(:event)).to eq(event)
          event.reload
        }.not_to change(event.teams, :count)
      end
    end

    describe "GET 'activate'" do
      it "should activate an inactive event" do
        event = FactoryGirl.create(:event, active: false, company: @company)
        expect {
          xhr :get, 'activate', id: event.to_param, format: :js
          expect(response).to be_success
          event.reload
        }.to change(event, :active).to(true)
      end
    end

    describe "GET 'deactivate'" do
      it "should deactivate an active event" do
        event = FactoryGirl.create(:event, active: true, company: @company)
        expect {
          xhr :get, 'deactivate', id: event.to_param, format: :js
          expect(response).to be_success
          event.reload
        }.to change(event, :active).to(false)
      end
    end

    describe "PUT 'submit'" do
      it "should submit event" do
        with_resque do
          event = FactoryGirl.create(:event, active: true, company: @company)
          @company_user.update_attributes(
            notifications_settings: ['event_recap_pending_approval_sms', 'event_recap_pending_approval_email'],
            user_attributes: {phone_number_verified: true} )
          event.users << @company_user
          message = "You have an event recap that is pending approval http://localhost:5100/events/#{event.id}"
          expect(UserMailer).to receive(:notification).with(@company_user.id, "Event Recaps Pending Approval", message).and_return(double(deliver: true))
          expect {
            xhr :put, 'submit', id: event.to_param, format: :js
            expect(response).to be_success
            event.reload
          }.to change(event, :submitted?).to(true)
          open_last_text_message_for @user.phone_number
          expect(current_text_message).to have_body message
        end
      end

      it "should not allow to submit the event if the event data is not valid" do
        campaign = FactoryGirl.create(:campaign, company_id: @company)
        field = FactoryGirl.create(:form_field_number, fieldable: campaign, kpi: FactoryGirl.create(:kpi, company_id: 1), required: true)
        event = FactoryGirl.create(:event, active: true, company: @company, campaign: campaign)
        expect {
          xhr :put, 'submit', id: event.to_param, format: :js
          expect(response).to be_success
          event.reload
        }.to_not change(event, :submitted?)
      end
    end

    describe "PUT 'approve'" do
      it "should approve event" do
        event = FactoryGirl.create(:submitted_event, active: true, company: @company)
        expect {
          put 'approve', id: event.to_param
          expect(response).to redirect_to(event_path(event, :status => 'approved'))
          event.reload
        }.to change(event, :approved?).to(true)
      end
    end

    describe "PUT 'reject'" do
      it "should reject event" do
        Timecop.freeze do
          with_resque do
            event = FactoryGirl.create(:submitted_event, active: true, company: @company)
            @company_user.update_attributes(
              notifications_settings: ['event_recap_rejected_sms', 'event_recap_rejected_email'],
              user_attributes: {phone_number_verified: true} )
            event.users << @company_user
            message = "You have a rejected event recap http://localhost:5100/events/#{event.id}"
            expect(UserMailer).to receive(:notification).with(@company_user.id, "Rejected Event Recaps", message).and_return(double(deliver: true))
            expect {
              xhr :put, 'reject', id: event.to_param, reason: 'blah blah blah', format: :js
              expect(response).to be_success
              event.reload
            }.to change(event, :rejected?).to(true)
            expect(event.reject_reason).to eq('blah blah blah')
            open_last_text_message_for @user.phone_number
            expect(current_text_message).to have_body message
          end
        end
      end
    end
  end

  describe "user with permissions to edit event data only" do
    before(:each) do
      @company_user = FactoryGirl.create(:company_user, company_id: FactoryGirl.create(:company).id, permissions: [[:show, 'Event'], [:edit_unsubmitted_data, 'Event']])
      @company = @company_user.company
      @user = @company_user.user
      sign_in @user
    end

    let(:event){ FactoryGirl.create(:event, company: @company) }

    it "should be able to edit event_data" do
      xhr :put, 'update', id: event.to_param, event: {results_attributes: {} }, format: :js
      expect(assigns(:event)).to eq(event)
      expect(response).to be_success
      expect(response).to render_template('events/_event')
    end
  end
end
