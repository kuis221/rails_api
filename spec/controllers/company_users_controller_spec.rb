require 'spec_helper'

describe CompanyUsersController do
  describe "as registered user" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.current_company
      @company_user = @user.current_company_user
    end

    describe "GET 'edit'" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }

      it "returns http success" do
        get 'edit', id: user.to_param, format: :js
        response.should be_success
      end
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        response.should be_success
      end

      describe "json requests" do
        it "responds to .table format" do
          get 'index', format: :json
          response.should be_success
        end

        it "returns the correct structure" do
          get 'index', format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body["total"].should == 0
          parsed_body["items"].should == []
          parsed_body["pages"].should == 1
          parsed_body["page"].should == 1
        end
      end
    end

    describe "GET 'event'" do
      let(:event) { FactoryGirl.create(:event, company: @company) }

      describe "json requests" do
        it "responds to .table format" do
          get 'event', event_id: event.id, format: :json
          response.should be_success
        end

        it "returns all the users associated with the event" do
          users = FactoryGirl.create_list(:user, 3, company_id: @company.id, role_id: @company_user.role_id)
          event.users << users.map(&:company_users).flatten

          get 'event', event_id: event.id, format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body["items"].size.should == 3
          parsed_body["total"].should == 3
          parsed_body["items"].map{|u| u['id']}.should =~ users.map(&:company_users).flatten.map(&:id)
          parsed_body["pages"].should == 1
          parsed_body["page"].should == 1
        end

        it "returns all the users associated with the teams associated with the event" do
          users = FactoryGirl.create_list(:user, 3, company_id: @company.id, role_id: @company_user.role_id)
          team = FactoryGirl.create(:team, company_id: @company.id)
          team.users << users.map(&:company_users).flatten
          event.teams << team

          get 'event', event_id: event.id, format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body["items"].size.should == 3
          parsed_body["total"].should == 3
          parsed_body["items"].map{|u| u['id']}.should =~ users.map(&:company_users).flatten.map(&:id)
          parsed_body["pages"].should == 1
          parsed_body["page"].should == 1
        end

        it "returns all the users from the teams associated with the event together with the users associated with the event" do

          other_users = FactoryGirl.create_list(:user, 3, company_id: @company.id, role_id: @company_user.role_id)
          team_users = FactoryGirl.create_list(:user, 3, company_id: @company.id, role_id: @company_user.role_id)
          team = FactoryGirl.create(:team, company_id: @company.id)
          team.users << team_users.map(&:company_users).flatten

          # Add some users to other team not associated with the event
          other_team_users = FactoryGirl.create_list(:user, 2, company_id: @company.id, role_id: @company_user.role_id)
          other_team = FactoryGirl.create(:team, company_id: @company.id)
          other_team.users << other_team_users.map(&:company_users).flatten

          # Associate the team and users with the event
          event.teams << team
          event.users << team_users.first.company_users
          event.users << other_users.map(&:company_users).flatten

          get 'event', event_id: event.id, format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body["items"].size.should == 6
          parsed_body["total"].should == 6
          parsed_body["items"].map{|u| u['id']}.should =~ (team_users + other_users).map(&:company_users).flatten.map(&:id)
          parsed_body["pages"].should == 1
          parsed_body["page"].should == 1
        end
      end
    end

    describe "GET 'show'" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company: @company) }

      it "returns http success" do
        get 'show', id: user.to_param
        response.should be_success
        assigns(:company_user).should == user
      end
    end

    describe "GET 'deactivate'" do
      let(:user){ FactoryGirl.create(:company_user, company_id: @company.id, active: true) }

      it "deactivates an active user" do
        user.active.should be_true
        get 'deactivate', id: user.to_param, format: :js
        response.should be_success
        user.reload.active?.should be_false
        user.active.should be_false
      end
    end

    describe "GET 'activate'" do
      let(:user){ FactoryGirl.create(:company_user, company_id: @company.id, active: false) }
      it "activates an inactive user" do
        user.active.should be_false
        get 'activate', id: user.to_param, format: :js
        response.should be_success
        user.reload.active?.should be_true
        user.active.should be_true
      end
    end

    describe "PUT 'update'" do
      let(:user){ FactoryGirl.create(:company_user, company_id: @company.id) }
      it "must update the user data" do
        put 'update', id: user.to_param, company_user: {user_attributes: {id: user.user_id,first_name: 'Juanito', last_name: 'Perez'}}, format: :js
        assigns(:company_user).should == user

        response.should be_success
        user.reload
        user.first_name.should == 'Juanito'
        user.last_name.should == 'Perez'
      end

      it "must update the user password" do
        old_password = user.user.encrypted_password
        put 'update', id: user.to_param, company_user: {user_attributes: {id: user.user_id, password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        assigns(:company_user).should == user
        response.should be_success
        user.reload
        user.user.encrypted_password.should_not == old_password
      end

      it "must update its own profile data" do
        old_password = @user.encrypted_password
        put 'update', id: @company_user.to_param, company_user: {user_attributes: {id: @user.id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com', city: 'Miami', state: 'FL', country: 'US', password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        assigns(:company_user).should == @company_user
        response.should be_success
        @user.reload
        @user.first_name.should == 'Juanito'
        @user.last_name.should == 'Perez'
        @user.email.should == @user.email
        @user.unconfirmed_email.should == 'test@testing.com'
        @user.city.should == 'Miami'
        @user.state.should == 'FL'
        @user.country.should == 'US'
        @user.encrypted_password.should_not == old_password
      end


      it "user have to enter the country/state and city information when editing his profifle" do
        old_password = @user.encrypted_password
        put 'update', id: @company_user.to_param, company_user: {user_attributes: {id: user.user_id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com', city: '', state: '', country: '', password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        assigns(:company_user).should == @company_user
        response.should be_success
        assigns(:company_user).errors.count.should > 0
        assigns(:company_user).errors['user.country'].should == ["can't be blank"]
        assigns(:company_user).errors['user.state'].should == ["can't be blank"]
        assigns(:company_user).errors['user.city'].should == ["can't be blank"]
      end

      it "allows admin to update teams and role" do
        team = FactoryGirl.create(:team, company: @company)
        role = FactoryGirl.create(:role, company: @company)
        put 'update', id: user.to_param, company_user: {role_id: role.id, team_ids: [team.id], user_attributes: {id: user.user_id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com',  password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        user.reload.role_id.should == role.id
        user.teams.should == [team]
      end

      it "allows admin to update invited users" do
        invited_user = FactoryGirl.create(:invited_user, company_id: @company.id )
        company_user = invited_user.company_users.first
        team = FactoryGirl.create(:team, company: @company)
        role = FactoryGirl.create(:role, company: @company)
        put 'update', id: company_user.to_param, company_user: {team_ids: [team.id], role_id: role.id, user_attributes: {id: invited_user.id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com'}}, format: :js
        company_user.reload.role_id.should == role.id
        company_user.teams.should == [team]
      end
    end

    describe "GET 'select_company'" do
      it 'should update the session with the selected company_id' do
        another_company_id = FactoryGirl.create(:company).id
        FactoryGirl.create(:company_user, company_id: another_company_id, user: @user, role_id: FactoryGirl.create(:role, company_id: another_company_id).id).id
        get 'select_company', company_id: another_company_id
        session[:current_company_id].should == another_company_id
        response.should redirect_to root_path
      end

      it 'should NOT update the session with a invalid company_id' do
        get 'select_company', company_id: 9999
        session[:current_company_id].should_not == 9999
        flash[:error].should == "You are not allowed login into this company"
        response.should redirect_to root_path
      end

      it 'should NOT update the session with a company_id if the user is not active on it' do
        another_company_id = FactoryGirl.create(:company_user, company: FactoryGirl.create(:company), user: @user, active: false).company_id
        get 'select_company', company_id: another_company_id
        session[:current_company_id].should_not == another_company_id
        flash[:error].should == "You are not allowed login into this company"
        response.should redirect_to root_path
      end
    end
  end
end
