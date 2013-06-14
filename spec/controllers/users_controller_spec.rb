require 'spec_helper'

describe UsersController do
  describe "as registered user" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.current_company
    end

    describe "GET 'edit'" do
      let(:user){ FactoryGirl.create(:user, company_id: @company.id) }

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
          get 'index', sEcho: 1, format: :json
          parsed_body = JSON.parse(response.body)
          parsed_body["total"].should == 0
          parsed_body["items"].should == []
          parsed_body["pages"].should == 1
          parsed_body["page"].should == 1
        end
      end
    end

    describe "GET 'deactivate'" do
      let(:user){ FactoryGirl.create(:user, company_id: @company.id, active: true) }

      it "deactivates an active user" do
        user.reload.company_users.first.active.should be_true
        get 'deactivate', id: user.to_param, format: :js
        response.should be_success
        user.reload.active?.should be_false
        user.company_users.first.active.should be_false
      end
    end

    describe "GET 'activate'" do
      let(:user){ FactoryGirl.create(:user, company_id: @company.id, active: false) }
      it "activates an inactive user" do
        user.reload.company_users.first.active.should be_false
        get 'activate', id: user.to_param, format: :js
        response.should be_success
        user.reload.active?.should be_true
        user.company_users.first.active.should be_true
      end
    end

    describe "PUT 'update'" do
      let(:user){ FactoryGirl.create(:user, company_id: @company.id) }
      it "must update the user data" do
        put 'update', id: user.to_param, user: {first_name: 'Juanito', last_name: 'Perez'}, format: :js
        assigns(:user).should == user

        response.should be_success
        user.reload
        user.first_name.should == 'Juanito'
        user.last_name.should == 'Perez'
      end

      it "must update the user password" do
        old_password = user.encrypted_password
        put 'update', id: user.to_param, user: {password: 'Juanito123', password_confirmation: 'Juanito123'}, format: :js
        assigns(:user).should == user
        response.should be_success
        user.reload
        user.encrypted_password.should_not == old_password
      end

      it "must update the its own profile data" do
        old_password = @user.encrypted_password
        put 'update', id: @user.to_param, user: {first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com', city: 'Miami', state: 'FL', country: 'US', password: 'Juanito123', password_confirmation: 'Juanito123'}, format: :js
        assigns(:user).should == @user
        response.should be_success
        @user.reload
        @user.first_name.should == 'Juanito'
        @user.last_name.should == 'Perez'
        @user.email.should == 'test@testing.com'
        @user.city.should == 'Miami'
        @user.state.should == 'FL'
        @user.country.should == 'US'
        @user.encrypted_password.should_not == old_password
      end


      it "user have to enter the countr/state and city information when editing his profifle" do
        old_password = @user.encrypted_password
        put 'update', id: @user.to_param, user: {first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com', city: '', state: '', country: '', password: 'Juanito123', password_confirmation: 'Juanito123'}, format: :js
        assigns(:user).should == @user
        response.should be_success

        assigns(:user).errors.count.should > 0
        assigns(:user).errors[:country].should == ["can't be blank"]
        assigns(:user).errors[:state].should == ["can't be blank"]
        assigns(:user).errors[:city].should == ["can't be blank"]
      end

      it "allows admin to update teams and role" do
        team = FactoryGirl.create(:team, company: @company)
        role = FactoryGirl.create(:role, company: @company)
        put 'update', id: user.to_param, user: {first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com',  password: 'Juanito123', password_confirmation: 'Juanito123', team_ids: [team.id], company_users_attributes: {"0"=>{role_id: role.id, id: user.company_users.first.id}}}, format: :js

        user.reload.company_users.first.role_id.should == role.id
        user.teams.should == [team]
      end

      it "allows admin to update invited users" do
        invited_user = FactoryGirl.create(:invited_user, company_id: @company.id )
        team = FactoryGirl.create(:team, company: @company)
        role = FactoryGirl.create(:role, company: @company)
        put 'update', id: invited_user.to_param, user: {first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com', team_ids: [team.id], company_users_attributes: {"0"=>{role_id: role.id, id: invited_user.company_users.first.id}}}, format: :js
        invited_user.reload.company_users.first.role_id.should == role.id
        invited_user.teams.should == [team]
      end
    end
  end
end
