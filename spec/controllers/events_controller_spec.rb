require 'spec_helper'

describe EventsController do
  describe "as registered user" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.companies.first
      @company_user = @user.current_company_user
    end

    describe "GET 'edit'" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "returns http success" do
        get 'edit', id: event.to_param, format: :js
        response.should be_success
      end
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        response.should be_success
      end

      describe "json requests" do
        it "responds to .json format" do
          get 'index', format: :json
          response.should be_success

          parsed_body = JSON.parse(response.body)
          parsed_body.count.should == 4
        end
      end
    end

    describe "GET 'autocomplete'", search: true do
      it "should return the correct buckets in the right order" do
        Sunspot.commit
        get 'autocomplete'
        response.should be_success

        buckets = JSON.parse(response.body)
        buckets.map{|b| b['label']}.should == ['Campaigns', 'Brands', 'Places', 'People']
      end

      it "should return the users in the People Bucket" do
        user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'gu'
        response.should be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'People'}.first
        people_bucket['value'].should == [{"label"=>"Guillermo Vargas", "value"=>company_user.id, "type"=>"companyuser"}]
      end

      it "should return the teams in the People Bucket" do
        team = FactoryGirl.create(:team, name: 'Spurs', company_id: @company.id)
        Sunspot.commit

        get 'autocomplete', q: 'sp'
        response.should be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'People'}.first
        people_bucket['value'].should == [{"label"=>"Spurs", "value"=>team.id, "type"=>"team"}]
      end

      it "should return the teams and users in the People Bucket" do
        team = FactoryGirl.create(:team, name: 'Valladolid', company_id: @company.id)
        user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'va'
        response.should be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select{|b| b['label'] == 'People'}.first
        people_bucket['value'].should == [{"label"=>"Valladolid", "value"=>team.id, "type"=>"team"}, {"label"=>"Guillermo Vargas", "value"=>company_user.id, "type"=>"companyuser"}]
      end

      it "should return the campaigns in the Campaigns Bucket" do
        campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        response.should be_success

        buckets = JSON.parse(response.body)
        campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
        campaigns_bucket['value'].should == [{"label"=>"Cacique para todos", "value"=>campaign.id, "type"=>"campaign"}]
      end

      it "should return the brands in the Brands Bucket" do
        brand = FactoryGirl.create(:brand, name: 'Cacique')
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        response.should be_success

        buckets = JSON.parse(response.body)
        brands_bucket = buckets.select{|b| b['label'] == 'Brands'}.first
        brands_bucket['value'].should == [{"label"=>"Cacique", "value"=>brand.id, "type"=>"brand"}]
      end

      it "should return the places in the Places Bucket" do
        Place.any_instance.should_receive(:fetch_place_data).and_return(true)
        place = FactoryGirl.create(:place, name: 'Motel Paraiso')
        Sunspot.commit

        get 'autocomplete', q: 'mot'
        response.should be_success

        buckets = JSON.parse(response.body)
        places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
        places_bucket['value'].should == [{"label"=>"Motel Paraiso", "value"=>place.id, "type"=>"place"}]
      end
    end

    describe "POST 'create'" do
      it "should not render form_dialog if no errors" do
        lambda {
          post 'create', event: {campaign_id: 1, start_date: '05/23/2020', start_time: '12:00pm', end_date: '05/22/2021', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        response.should be_success
        response.should render_template(:create)
        response.should_not render_template(:form_dialog)
      end

      it "should render the form_dialog template if errors" do
        lambda {
          post 'create', format: :js
        }.should_not change(Event, :count)
        response.should render_template(:create)
        response.should render_template(:form_dialog)
        assigns(:event).errors.count > 0
      end

      it "should assign current_user's company_id to the new event" do
        lambda {
          post 'create', event: {campaign_id: 1, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2021', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        assigns(:event).company_id.should == @company.id
      end

    end


    describe "PUT 'update'" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "must update the user attributes" do
        put 'update', id: event.to_param, event: {campaign_id: 111, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        assigns(:event).should == event
        response.should be_success
        event.reload
        event.campaign_id.should == 111
        event.start_at.should == Time.zone.parse('2020-05-21 12:00:00')
        event.end_at.should == Time.zone.parse('2020-05-22 13:00:00')
      end
    end

    describe "DELETE 'delete_member' with a user" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it "should remove the team member from the event" do
        event.users << @company_user
        lambda{
          delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.users, :count).by(-1)
      end

      it "should unassign any tasks assigned the user" do
        event.users << @company_user
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user_id: @company_user.id+1)
        delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js

        user_tasks.each{|t| t.reload.company_user_id.should be_nil }
        other_tasks.each{|t| t.reload.company_user_id.should_not be_nil }
      end

      it "should not raise error if the user doesn't belongs to the event" do
        delete 'delete_member', id: event.id, member_id: @company_user.id, format: :js
        event.reload
        response.should be_success
        assigns(:event).should == event
      end
    end

    describe "DELETE 'delete_member' with a team" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      let(:team){ FactoryGirl.create(:team, company: @company) }
      it "should remove the team from the event" do
        event.teams << team
        lambda{
          delete 'delete_member', id: event.id, team_id: team.id, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.teams, :count).by(-1)
      end

      it "should unassign any tasks assigned the team users" do
        team.users << @company_user
        event.teams << team
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user_id: @company_user.id+1)
        delete 'delete_member', id: event.id, team_id: team.id, format: :js

        user_tasks.each{|t| t.reload.company_user_id.should be_nil }
        other_tasks.each{|t| t.reload.company_user_id.should_not be_nil }

      end

      it "should not unassign any tasks assigned the team users if the user is directly assigned to the event" do
        team.users << @company_user
        event.users << @company_user
        event.teams << team
        user_tasks = FactoryGirl.create_list(:task, 3, event: event, company_user: @company_user)
        other_tasks = FactoryGirl.create_list(:task, 2, event: event, company_user_id: @company_user.id+1)
        delete 'delete_member', id: event.id, team_id: team.id, format: :js

        user_tasks.each{|t| t.reload.company_user_id.should == @company_user.id }
        other_tasks.each{|t| t.reload.company_user_id.should_not be_nil }
      end

      it "should not raise error if the team doesn't belongs to the event" do
        delete 'delete_member', id: event.id, team_id: team.id, format: :js
        event.reload
        response.should be_success
        assigns(:event).should == event
      end
    end

    describe "GET 'new_member" do
      let(:event){ FactoryGirl.create(:event, company: @company) }
      it 'should load all the company\'s users into @users' do
        FactoryGirl.create(:user, company_id: @company.id+1)
        get 'new_member', id: event.id, format: :js
        response.should be_success
        assigns(:event).should == event
        assigns(:users).should == [@company_user]
      end

      it 'should not load the users that are already assigned to the event' do
        another_user = FactoryGirl.create(:company_user, company_id: @company.id, role_id: @company_user.role_id)
        event.users << @company_user
        get 'new_member', id: event.id, format: :js
        response.should be_success
        assigns(:event).should == event
        assigns(:users).should == [another_user]
      end

      it 'should load teams with active users' do
        team = FactoryGirl.create(:team, company_id: @company.id)
        team.users << @company_user
        get 'new_member', id: event.id, format: :js
        assigns(:teams).should == [team]
        assigns(:assignable_teams).should == [team]
      end

      it 'should not load teams without assignable users' do
        team = FactoryGirl.create(:team, company_id: @company.id)
        get 'new_member', id: event.id, format: :js
        assigns(:teams).should == [team]
        assigns(:assignable_teams).should == []
      end
    end


    describe "POST 'add_members" do
      let(:event){ FactoryGirl.create(:event, company: @company) }

      it 'should assign the user to the event' do
        lambda {
          post 'add_members', id: event.id, member_id: @company_user.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.users, :count).by(1)
        event.users.should == [@company_user]
      end

      it 'should assign all the team to the event' do
        team = FactoryGirl.create(:team, company_id: @company.id)
        lambda {
          post 'add_members', id: event.id, team_id: team.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.teams, :count).by(1)
        event.teams.should == [team]
      end

      it 'should not assign users to the event if they are already part of the event' do
        event.users << @company_user
        lambda {
          post 'add_members', id: event.id, member_id: @company_user.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should_not change(event.users, :count)
      end

      it 'should not assign teams to the event if they are already part of the event' do
        team = FactoryGirl.create(:team, company_id: @company.id)
        event.teams << team
        lambda {
          post 'add_members', id: event.id, team_id: team.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should_not change(event.teams, :count)
      end
    end

    describe "GET 'activate'" do
      it "should activate an inactive event" do
        event = FactoryGirl.create(:event, active: false, company: @company)
        lambda {
          get 'activate', id: event.to_param, format: :js
          response.should be_success
          event.reload
        }.should change(event, :active).to(true)
      end
    end

    describe "GET 'deactivate'" do
      it "should deactivate an active event" do
        event = FactoryGirl.create(:event, active: true, company: @company)
        lambda {
          get 'deactivate', id: event.to_param, format: :js
          response.should be_success
          event.reload
        }.should change(event, :active).to(false)
      end
    end
  end

end
