require 'spec_helper'

describe EventsController do
  describe "as registered user" do
    before(:each) do
      @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id)
      sign_in @user
    end

    describe "GET 'edit'" do
      let(:event){ FactoryGirl.create(:event) }
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

      describe "datatable requests" do
        it "responds to .table format" do
          get 'index', format: :table
          response.should be_success
        end

        it "returns the correct structure" do
          FactoryGirl.create_list(:event, 3, company_id: @user.company_id)

          # Events on other companies should not be included on the results
          FactoryGirl.create_list(:event, 2, company_id: 9999)
          get 'index', sEcho: 1, format: :table
          parsed_body = JSON.parse(response.body)
          parsed_body["sEcho"].should == 1
          parsed_body["iTotalRecords"].should == 3
          parsed_body["iTotalDisplayRecords"].should == 3
          parsed_body["aaData"].count.should == 3
        end
      end
    end

    describe "POST 'create'" do
      it "returns http success" do
        post 'create', format: :js
        response.should be_success
      end

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

      it "should assign current_user's company_id to the new user" do
        lambda {
          post 'create', event: {campaign_id: 1, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2021', end_time: '01:00pm'}, format: :js
        }.should change(Event, :count).by(1)
        assigns(:event).company_id.should == @user.company_id
      end
    end


    describe "PUT 'update'" do
      let(:event){ FactoryGirl.create(:event) }
      it "must update the user attributes" do
        put 'update', id: event.to_param, event: {campaign_id: 111, start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020', end_time: '01:00pm'}, format: :js
        assigns(:event).should == event
        response.should be_success
        event.reload
        event.campaign_id.should == 111
        event.start_at.should == DateTime.parse('2020-05-21 12:00:00')
        event.end_at.should == DateTime.parse('2020-05-22 13:00:00')
      end
    end

    describe "DELETE 'delete_member'" do
      let(:event){ FactoryGirl.create(:event) }
      it "should remove the team member from the event" do
        event.users << @user
        lambda{
          delete 'delete_member', id: event.id, member_id: @user.id, format: :js
          response.should be_success
          assigns(:event).should == event
          event.reload
        }.should change(event.users, :count).by(-1)
      end

      it "should not raise error if the user doesn't belongs to the team" do
        delete 'delete_member', id: event.id, member_id: @user.id, format: :js
        event.reload
        response.should be_success
        assigns(:event).should == event
      end
    end

    describe "GET 'new_member" do
      let(:event){ FactoryGirl.create(:event) }
      it 'should be sucess' do
        get 'new_member', id: event.id, format: :js
        response.should be_success
        assigns(:event).should == event
      end
    end


    describe "POST 'add_members" do
      let(:event){ FactoryGirl.create(:event) }
      it 'should assign the user to the event' do
        lambda {
          post 'add_members', id: event.id, member_id: @user.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          assigns(:members).should == [@user]
          event.reload
        }.should change(event.users, :count).by(1)
      end

      it 'should assign all the team\'s users to the event' do
        expected_users = FactoryGirl.create_list(:user, 3, company_id: @user.company_id)
        team = FactoryGirl.create(:team, company_id: @user.company_id)
        lambda {
          expected_users.each{|u| team.users  << u }
          post 'add_members', id: event.id, team_id: team.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          assigns(:members).should =~ expected_users
          event.reload
        }.should change(event.users, :count).by(3)
        event.users.should =~ expected_users
      end

      it 'should not assign users to the event if they are already part of the event' do
        team = FactoryGirl.create(:team, company_id: @user.company_id)
        team.users << @user
        event.users << @user
        lambda {
          post 'add_members', id: event.id, team_id: team.to_param, format: :js
          response.should be_success
          assigns(:event).should == event
          assigns(:members).should =~ [@user]
          event.reload
        }.should_not change(event.users, :count)
      end
    end

    describe "GET 'activate'" do
      it "should activate an inactive event" do
        event = FactoryGirl.create(:event, active: false)
        lambda {
          get 'activate', id: event.to_param, format: :js
          response.should be_success
          event.reload
        }.should change(event, :active).to(true)
      end
    end

    describe "GET 'deactivate'" do
      it "should deactivate an active event" do
        event = FactoryGirl.create(:event, active: true)
        lambda {
          get 'deactivate', id: event.to_param, format: :js
          response.should be_success
          event.reload
        }.should change(event, :active).to(false)
      end
    end
  end

end
