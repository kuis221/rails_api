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
    end

    describe "GET 'items'" do
      it "returns http success " do
        get 'index', format: :json
        response.should be_success
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

      it "user have to enter the phone number, country/state, city, street address and zip code information when editing his profile" do
        old_password = @user.encrypted_password
        controller.should_receive(:can?).twice.with(:super_update, @company_user).and_return false
        controller.should_receive(:can?).any_number_of_times.and_return true
        put 'update', id: @company_user.to_param, company_user: {user_attributes: {id: user.user_id, first_name: 'Juanito', last_name: 'Perez', email: 'test@testing.com', phone_number: '', city: '', state: '', country: '', street_address: '', zip_code: '', password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        response.should be_success
        assigns(:company_user).errors.count.should > 0
        assigns(:company_user).errors['user.phone_number'].should == ["can't be blank"]
        assigns(:company_user).errors['user.country'].should == ["can't be blank"]
        assigns(:company_user).errors['user.state'].should == ["can't be blank"]
        assigns(:company_user).errors['user.city'].should == ["can't be blank"]
        assigns(:company_user).errors['user.street_address'].should == ["can't be blank"]
        assigns(:company_user).errors['user.zip_code'].should == ["can't be blank"]
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
        put 'update', id: company_user.to_param, company_user: {team_ids: [team.id], role_id: role.id, notifications_settings: ["event_recap_late_sms", "event_recap_pending_approval_email", "new_event_team_app"], user_attributes: {id: invited_user.id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com'}}, format: :js
        company_user.reload.role_id.should == role.id
        company_user.teams.should == [team]
        company_user.notifications_settings.should include("event_recap_late_sms", "event_recap_pending_approval_email", "new_event_team_app")
      end
    end

    describe "GET 'profile'" do
      it 'should render the correct template' do
        get 'profile'
        expect(assigns(:company_user)).to eql @company_user
        response.should render_template 'show'
      end
    end

    describe "GET 'send_code'" do
      it 'should render the correct templates' do
        get 'send_code', id: @company_user.to_param, format: :js
        expect(assigns(:company_user)).to eql @company_user
        response.should render_template 'send_code'
        response.should render_template '_form_dialog'
        response.should render_template '_send_code'
      end
    end

    describe "POST 'verify_phone'" do
      it 'should update the phone_number_verification for the user' do
        expect(@company_user.user.phone_number_verification).to be_nil
        get 'verify_phone', id: @company_user.to_param, format: :js
        expect(assigns(:company_user)).to eql @company_user
        response.should render_template 'verify_phone'
        expect(@company_user.user.reload.phone_number_verification).to_not be_nil
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

    describe "DELETE 'remove_campaign'" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
      let(:campaign){ FactoryGirl.create(:campaign, company_id: @company.id) }
      let(:brand){ FactoryGirl.create(:brand) }

      it 'should remove a campaing is assigned to the user' do
        user.campaigns << campaign
        expect {
          delete 'remove_campaign', id: user.id, campaign_id: campaign.id, format: :js
          response.should be_success
          user.reload
        }.to change(user.campaigns, :count).by(-1)

        response.should render_template('remove_campaign')
      end

      it 'should remove a campaing is assigned to the user through a brand' do
        user.memberships.create(parent: brand, memberable: campaign)
        expect {
          delete 'remove_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          response.should be_success
          user.reload
        }.to change(user.campaigns, :count).by(-1)

        response.should render_template('remove_campaign')
      end

      it 'should deassign the brand from the user and assign any other campaigns that is part of this brand' do
        campaign2 = FactoryGirl.create(:campaign, company_id: @company.id)
        campaign.brands << brand
        campaign2.brands << brand

        user.memberships.create(parent: brand, memberable: brand).should be_true
        expect {
          delete 'remove_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          response.should be_success
          user.reload
        }.to_not change(user.memberships, :count)  # Remove the parent and add the campaign2 as a member

        user.memberships.map(&:memberable).should == [campaign2]

        response.should render_template('remove_campaign')
      end
    end

    describe "add_campaign" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
      let(:campaign){ FactoryGirl.create(:campaign, company_id: @company.id) }
      let(:brand){ FactoryGirl.create(:brand) }

      it "should add a campaign to the user that belongs to a brand" do
        campaign.brands << brand
        expect {
          post 'add_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          response.should be_success
          user.reload
        }.to change(user.memberships, :count).by(1)

        user.memberships.map(&:parent).should == [brand]
        user.memberships.map(&:memberable).should == [campaign]
        user.campaigns.should == [campaign]
      end
    end

    describe "disable_campaigns" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
      let(:campaign){ FactoryGirl.create(:campaign, company_id: @company.id) }
      let(:brand){ FactoryGirl.create(:brand) }

      it "remove the brand as a membership and assign any campaign to the user with the brand as parent" do
        campaign.brands << brand
        user.brands << brand
        expect {
          post 'disable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          response.should be_success
          user.reload
        }.to change(user.brands, :count).by(-1)

        user.memberships.map(&:parent).should == [brand]
        user.memberships.map(&:memberable).should == [campaign]
        user.campaigns.should == [campaign]
      end

      it "should now fail if invalid parent params were provided" do
        post 'disable_campaigns', id: user.id, parent_id: '6669999', parent_type: 'Brand', format: :js
        response.should be_success
      end
    end


    describe "enable_campaigns" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
      let(:campaign){ FactoryGirl.create(:campaign, company_id: @company.id) }
      let(:brand){ FactoryGirl.create(:brand) }

      it "remove the brand as a membership and assign any campaign to the user with the brand as parent" do
        campaign.brands << brand
        expect {
          post 'enable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          response.should be_success
          user.reload
        }.to change(user.brands, :count).by(1)

        user.memberships.map(&:parent).should == [nil]
        user.memberships.map(&:memberable).should == [brand]
        user.campaigns.should == []
      end

      it "should not create another membership if there is one already" do
        campaign.brands << brand
        user.memberships.create(memberable: brand)
        user.reload
        expect {
          post 'enable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          response.should be_success
        }.to_not change(user.memberships, :count)

      end
    end
  end
end
