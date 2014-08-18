require 'spec_helper'

describe CompanyUsersController, :type => :controller do
  describe "as registered user" do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.current_company
      @company_user = @user.current_company_user
    end

    describe "GET 'edit'" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }

      it "returns http success" do
        xhr :get, 'edit', id: user.to_param, format: :js
        expect(response).to be_success
      end
    end

    describe "GET 'index'" do
      it "returns http success" do
        get 'index'
        expect(response).to be_success
      end
    end

    describe "GET 'items'" do
      it "returns http success " do
        get 'index', format: :json
        expect(response).to be_success
      end
    end

    describe "GET 'show'" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company: @company) }

      it "returns http success" do
        get 'show', id: user.to_param
        expect(response).to be_success
        expect(assigns(:company_user)).to eq(user)
      end
    end

    describe "GET 'deactivate'" do
      let(:user){ FactoryGirl.create(:company_user, company_id: @company.id, active: true) }

      it "deactivates an active user" do
        expect(user.active).to be_truthy
        xhr :get, 'deactivate', id: user.to_param, format: :js
        expect(response).to be_success
        expect(user.reload.active?).to be_falsey
        expect(user.active).to be_falsey
      end
    end

    describe "GET 'activate'" do
      let(:user){ FactoryGirl.create(:company_user, company_id: @company.id, active: false) }
      it "activates an inactive user" do
        expect(user.active).to be_falsey
        xhr :get, 'activate', id: user.to_param, format: :js
        expect(response).to be_success
        expect(user.reload.active?).to be_truthy
        expect(user.active).to be_truthy
      end
    end

    describe "PUT 'update'" do
      let(:user){ FactoryGirl.create(:company_user, company_id: @company.id) }
      it "must update the user data" do
        xhr :put, 'update', id: user.to_param, company_user: {user_attributes: {id: user.user_id,first_name: 'Juanito', last_name: 'Perez'}}, format: :js
        expect(assigns(:company_user)).to eq(user)

        expect(response).to be_success
        user.reload
        expect(user.first_name).to eq('Juanito')
        expect(user.last_name).to eq('Perez')
      end

      it "must update the user password" do
        old_password = user.user.encrypted_password
        xhr :put, 'update', id: user.to_param, company_user: {user_attributes: {id: user.user_id, password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        expect(assigns(:company_user)).to eq(user)
        expect(response).to be_success
        user.reload
        expect(user.user.encrypted_password).not_to eq(old_password)
      end

      it "must update its own profile data" do
        old_password = @user.encrypted_password
        xhr :put, 'update', id: @company_user.to_param, company_user: {user_attributes: {id: @user.id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com', city: 'Miami', state: 'FL', country: 'US', password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        expect(assigns(:company_user)).to eq(@company_user)
        expect(response).to be_success
        @user.reload
        expect(@user.first_name).to eq('Juanito')
        expect(@user.last_name).to eq('Perez')
        expect(@user.email).to eq(@user.email)
        expect(@user.unconfirmed_email).to eq('test@testing.com')
        expect(@user.city).to eq('Miami')
        expect(@user.state).to eq('FL')
        expect(@user.country).to eq('US')
        expect(@user.encrypted_password).not_to eq(old_password)
      end

      it "user have to enter the phone number, country/state, city, street address and zip code information when editing his profile" do
        old_password = @user.encrypted_password
        expect(controller).to receive(:can?).twice.with(:super_update, @company_user).and_return false
        expect(controller).to receive(:can?).at_least(:once).and_return true
        xhr :put, 'update', id: @company_user.to_param, company_user: {user_attributes: {id: user.user_id, first_name: 'Juanito', last_name: 'Perez', email: 'test@testing.com', phone_number: '', city: '', state: '', country: '', street_address: '', zip_code: '', password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        expect(response).to be_success
        expect(assigns(:company_user).errors.count).to be > 0
        expect(assigns(:company_user).errors['user.phone_number']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.country']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.state']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.city']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.street_address']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.zip_code']).to eq(["can't be blank"])
      end

      it "allows admin to update teams and role" do
        team = FactoryGirl.create(:team, company: @company)
        role = FactoryGirl.create(:role, company: @company)
        xhr :put, 'update', id: user.to_param, company_user: {role_id: role.id, team_ids: [team.id], user_attributes: {id: user.user_id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com',  password: 'Juanito123', password_confirmation: 'Juanito123'}}, format: :js
        expect(user.reload.role_id).to eq(role.id)
        expect(user.teams).to eq([team])
      end

      it "allows admin to update invited users" do
        invited_user = FactoryGirl.create(:invited_user, company_id: @company.id )
        company_user = invited_user.company_users.first
        team = FactoryGirl.create(:team, company: @company)
        role = FactoryGirl.create(:role, company: @company)
        xhr :put, 'update', id: company_user.to_param, company_user: {team_ids: [team.id], role_id: role.id, notifications_settings: ["event_recap_late_sms", "event_recap_pending_approval_email", "new_event_team_app"], user_attributes: {id: invited_user.id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com'}}, format: :js
        expect(company_user.reload.role_id).to eq(role.id)
        expect(company_user.teams).to eq([team])
        expect(company_user.notifications_settings).to include("event_recap_late_sms", "event_recap_pending_approval_email", "new_event_team_app")
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
        xhr :get, 'send_code', id: @company_user.to_param, format: :js
        expect(assigns(:company_user)).to eql @company_user
        expect(response).to render_template 'send_code'
        expect(response).to render_template '_form_dialog'
        expect(response).to render_template '_send_code'
      end
    end

    describe "POST 'verify_phone'" do
      it 'should update the phone_number_verification for the user' do
        expect(@company_user.user.phone_number_verification).to be_nil
        xhr :get, 'verify_phone', id: @company_user.to_param, format: :js
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
        expect(session[:current_company_id]).to eq(another_company_id)
        expect(response).to redirect_to root_path
      end

      it 'should NOT update the session with a invalid company_id' do
        get 'select_company', company_id: 9999
        expect(session[:current_company_id]).not_to eq(9999)
        expect(flash[:error]).to eq("You are not allowed login into this company")
        expect(response).to redirect_to root_path
      end

      it 'should NOT update the session with a company_id if the user is not active on it' do
        another_company_id = FactoryGirl.create(:company_user, company: FactoryGirl.create(:company), user: @user, active: false).company_id
        get 'select_company', company_id: another_company_id
        expect(session[:current_company_id]).not_to eq(another_company_id)
        expect(flash[:error]).to eq("You are not allowed login into this company")
        expect(response).to redirect_to root_path
      end
    end

    describe "DELETE 'remove_campaign'" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
      let(:campaign){ FactoryGirl.create(:campaign, company_id: @company.id) }
      let(:brand){ FactoryGirl.create(:brand, company: @company) }

      it 'should remove a campaing is assigned to the user' do
        user.campaigns << campaign
        expect {
          delete 'remove_campaign', id: user.id, campaign_id: campaign.id, format: :js
          expect(response).to be_success
          user.reload
        }.to change(user.campaigns, :count).by(-1)

        expect(response).to render_template('remove_campaign')
      end

      it 'should remove a campaing is assigned to the user through a brand' do
        user.memberships.create(parent: brand, memberable: campaign)
        expect {
          delete 'remove_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          expect(response).to be_success
          user.reload
        }.to change(user.campaigns, :count).by(-1)

        expect(response).to render_template('remove_campaign')
      end

      it 'should deassign the brand from the user and assign any other campaigns that is part of this brand' do
        campaign2 = FactoryGirl.create(:campaign, company_id: @company.id)
        campaign.brands << brand
        campaign2.brands << brand

        expect(user.memberships.create(parent: brand, memberable: brand)).to be_truthy
        expect {
          delete 'remove_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          expect(response).to be_success
          user.reload
        }.to_not change(user.memberships, :count)  # Remove the parent and add the campaign2 as a member

        expect(user.memberships.map(&:memberable)).to eq([campaign2])

        expect(response).to render_template('remove_campaign')
      end
    end

    describe "add_campaign" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
      let(:campaign){ FactoryGirl.create(:campaign, company_id: @company.id) }
      let(:brand){ FactoryGirl.create(:brand) }

      it "should add a campaign to the user that belongs to a brand" do
        campaign.brands << brand
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{user.id}")
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{user.id}").at_least(:once)
        expect {
          xhr :post, 'add_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          expect(response).to be_success
          user.reload
        }.to change(user.memberships, :count).by(1)

        expect(user.memberships.map(&:parent)).to eq([brand])
        expect(user.memberships.map(&:memberable)).to eq([campaign])
        expect(user.campaigns).to eq([campaign])
      end
    end

    describe "disable_campaigns" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
      let(:campaign){ FactoryGirl.create(:campaign, company_id: @company.id) }
      let(:brand){ FactoryGirl.create(:brand, company: @company) }

      it "remove the brand as a membership and assign any campaign to the user with the brand as parent" do
        campaign.brands << brand
        user.brands << brand
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{user.id}").at_least(:once)
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{user.id}").at_least(:once)
        expect {
          xhr :post, 'disable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          expect(response).to be_success
          user.reload
        }.to change(user.brands, :count).by(-1)

        expect(user.memberships.map(&:parent)).to eq([brand])
        expect(user.memberships.map(&:memberable)).to eq([campaign])
        expect(user.campaigns).to eq([campaign])
      end

      it "should now fail if invalid parent params were provided" do
        xhr :post, 'disable_campaigns', id: user.id, parent_id: '6669999', parent_type: 'Brand', format: :js
        expect(response).to be_success
      end
    end

    describe "enable_campaigns" do
      let(:user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user), company_id: @company.id) }
      let(:campaign){ FactoryGirl.create(:campaign, company_id: @company.id) }
      let(:brand){ FactoryGirl.create(:brand, company: @company) }
      let(:brand_portfolio){ FactoryGirl.create(:brand_portfolio, company: @company) }

      it "remove the brand as a membership and assign any campaign to the user with the brand as parent" do
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{user.id}")
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{user.id}").at_least(:once)
        campaign.brands << brand
        expect {
          xhr :post, 'enable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          expect(response).to be_success
          user.reload
        }.to change(user.brands, :count).by(1)

        expect(user.memberships.map(&:parent)).to eq([nil])
        expect(user.memberships.map(&:memberable)).to eq([brand])
        expect(user.campaigns).to eq([])
      end

      it "should not create another membership if there is one already" do
        campaign.brands << brand
        user.memberships.create(memberable: brand)
        user.reload

        expect(Rails.cache).to_not receive(:delete).with("user_accessible_campaigns_#{user.id}")
        expect {
          xhr :post, 'enable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          expect(response).to be_success
        }.to_not change(user.memberships, :count)
      end

      it "should create a relationship between users and brand portfolio" do
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{user.id}")
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{user.id}").at_least(:once)
        expect {
          xhr :post, 'enable_campaigns', id: user.id, parent_id: brand_portfolio.id, parent_type: 'BrandPortfolio', format: :js
          expect(response).to be_success
          user.reload
        }.to change(user.brand_portfolios, :count).by(1)

        expect(user.memberships.map(&:parent)).to eq([nil])
        expect(user.memberships.map(&:memberable)).to eq([brand_portfolio])
        expect(user.campaigns).to eq([])
      end
    end
  end
end
