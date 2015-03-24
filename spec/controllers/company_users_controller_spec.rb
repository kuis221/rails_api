require 'rails_helper'

describe CompanyUsersController, type: :controller do
  describe 'as registered user' do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.current_company
      @company_user = @user.current_company_user
    end

    describe "GET 'edit'" do
      let(:user) { create(:company_user, user: create(:user), company_id: @company.id) }

      it 'returns http success' do
        xhr :get, 'edit', id: user.to_param, format: :js
        expect(response).to be_success
      end
    end

    describe "GET 'index'" do
      it 'returns http success' do
        get 'index'
        expect(response).to be_success
      end

      it 'queue the job for export the list to XLS' do
        expect do
          xhr :get, :index, format: :xls
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        expect(export.controller).to eql('CompanyUsersController')
        expect(export.export_format).to eql('xls')
      end

      it 'queue the job for export the list to PDF' do
        expect do
          xhr :get, :index, format: :pdf
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        expect(export.controller).to eql('CompanyUsersController')
        expect(export.export_format).to eql('pdf')
      end
    end

    describe "GET 'items'" do
      it 'returns http success ' do
        get 'index', format: :json
        expect(response).to be_success
      end
    end

    describe "GET 'show'" do
      let(:user) { create(:company_user, user: create(:user), company: @company) }

      it 'returns http success' do
        get 'show', id: user.to_param
        expect(response).to be_success
        expect(assigns(:company_user)).to eq(user)
      end
    end

    describe "GET 'deactivate'" do
      let(:user) { create(:company_user, company_id: @company.id, active: true) }

      it 'deactivates an active user' do
        expect(user.active).to be_truthy
        xhr :get, 'deactivate', id: user.to_param, format: :js
        expect(response).to be_success
        expect(user.reload.active?).to be_falsey
        expect(user.active).to be_falsey
      end
    end

    describe "GET 'activate'" do
      let(:user) { create(:company_user, company_id: @company.id, active: false) }
      it 'activates an inactive user' do
        expect(user.active).to be_falsey
        xhr :get, 'activate', id: user.to_param, format: :js
        expect(response).to be_success
        expect(user.reload.active?).to be_truthy
        expect(user.active).to be_truthy
      end
    end

    describe "PUT 'update'" do
      let(:user) { create(:company_user, company_id: @company.id) }
      it 'must update the user data' do
        xhr :put, 'update', id: user.to_param, company_user: { user_attributes: { id: user.user_id, first_name: 'Juanito', last_name: 'Perez' } }, format: :js
        expect(assigns(:company_user)).to eq(user)

        expect(response).to be_success
        user.reload
        expect(user.first_name).to eq('Juanito')
        expect(user.last_name).to eq('Perez')
      end

      it 'must update the user password' do
        old_password = user.user.encrypted_password
        xhr :put, 'update', id: user.to_param, company_user: { user_attributes: { id: user.user_id, password: 'Juanito123', password_confirmation: 'Juanito123' } }, format: :js
        expect(assigns(:company_user)).to eq(user)
        expect(response).to be_success
        user.reload
        expect(user.user.encrypted_password).not_to eq(old_password)
      end

      it 'must update its own profile data' do
        old_password = @user.encrypted_password
        xhr :put, 'update', id: @company_user.to_param, company_user: { user_attributes: { id: @user.id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com', city: 'Miami', state: 'FL', country: 'US', password: 'Juanito123', password_confirmation: 'Juanito123' } }, format: :js
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

        expect(flash[:info]).to eql 'A confirmation email was sent to test@testing.com. '\
                                    'Your email will not be changed until you complete this step.'
      end

      it 'user have to enter the phone number, country/state, city, street address and zip code information when editing his profile' do
        old_password = @user.encrypted_password
        expect(controller).to receive(:can?).twice.with(:super_update, @company_user).and_return false
        expect(controller).to receive(:can?).at_least(:once).and_return true
        xhr :put, 'update', id: @company_user.to_param, company_user: { user_attributes: { id: user.user_id, first_name: 'Juanito', last_name: 'Perez', email: 'test@testing.com', phone_number: '', city: '', state: '', country: '', street_address: '', zip_code: '', password: 'Juanito123', password_confirmation: 'Juanito123' } }, format: :js
        expect(response).to be_success
        expect(assigns(:company_user).errors.count).to be > 0
        expect(assigns(:company_user).errors['user.phone_number']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.country']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.state']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.city']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.street_address']).to eq(["can't be blank"])
        expect(assigns(:company_user).errors['user.zip_code']).to eq(["can't be blank"])
      end

      it 'allows admin to update teams and role' do
        team = create(:team, company: @company)
        role = create(:role, company: @company)
        xhr :put, 'update', id: user.to_param, company_user: { role_id: role.id, team_ids: [team.id], user_attributes: { id: user.user_id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com',  password: 'Juanito123', password_confirmation: 'Juanito123' } }, format: :js
        expect(user.reload.role_id).to eq(role.id)
        expect(user.teams).to eq([team])
      end

      it 'allows admin to update invited users' do
        invited_user = create(:invited_user, company_id: @company.id)
        company_user = invited_user.company_users.first
        team = create(:team, company: @company)
        role = create(:role, company: @company)
        xhr :put, 'update', id: company_user.to_param, company_user: { team_ids: [team.id], role_id: role.id, notifications_settings: %w(event_recap_late_sms event_recap_pending_approval_email new_event_team_app), user_attributes: { id: invited_user.id, first_name: 'Juanito', last_name: 'Perez',  email: 'test@testing.com' } }, format: :js
        expect(company_user.reload.role_id).to eq(role.id)
        expect(company_user.teams).to eq([team])
        expect(company_user.notifications_settings).to include('event_recap_late_sms', 'event_recap_pending_approval_email', 'new_event_team_app')
      end
    end

    describe "GET 'resend_email_confirmation'" do
      it 'should be successs' do
        @company_user.user.update_column('unconfirmed_email', 'email@prueba.com')
        expect_any_instance_of(User).to receive(:send_confirmation_instructions)
        xhr :get, 'resend_email_confirmation', id: @company_user.to_param, format: :js
        expect(assigns(:company_user)).to eql @company_user
        expect(response).to be_success
      end
    end

    describe "GET 'cancel_email_change'" do
      it 'should be successs' do
        @company_user.user.update_column('unconfirmed_email', 'email@prueba.com')
        expect(@company_user.user.unconfirmed_email).not_to be_nil
        expect(@company_user.user.confirmation_token).not_to be_nil

        xhr :get, 'cancel_email_change', id: @company_user.to_param, format: :js
        @company_user.reload
        expect(response).to be_success
        expect(@company_user.user.unconfirmed_email).to be_nil
        expect(@company_user.user.confirmation_token).to be_nil
      end
    end

    describe "GET 'profile'" do
      it 'should render the correct template' do
        get 'profile'
        expect(assigns(:company_user)).to eql @company_user
        expect(response).to render_template 'show'
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
        expect(response).to render_template 'verify_phone'
        expect(@company_user.user.reload.phone_number_verification).to_not be_nil
      end
    end

    describe "GET 'select_company'" do
      it 'should update the session with the selected company_id' do
        another_company_id = create(:company).id
        create(:company_user, company_id: another_company_id, user: @user, role_id: create(:role, company_id: another_company_id).id).id
        get 'select_company', company_id: another_company_id
        expect(session[:current_company_id]).to eq(another_company_id)
        expect(response).to redirect_to root_path
      end

      it 'should NOT update the session with a invalid company_id' do
        get 'select_company', company_id: 9999
        expect(session[:current_company_id]).not_to eq(9999)
        expect(flash[:error]).to eq('You are not allowed login into this company')
        expect(response).to redirect_to root_path
      end

      it 'should NOT update the session with a company_id if the user is not active on it' do
        another_company_id = create(:company_user, company: create(:company), user: @user, active: false).company_id
        get 'select_company', company_id: another_company_id
        expect(session[:current_company_id]).not_to eq(another_company_id)
        expect(flash[:error]).to eq('You are not allowed login into this company')
        expect(response).to redirect_to root_path
      end
    end

    describe "GET 'select_campaigns'" do
      let(:user) { create(:company_user, user: create(:user), company_id: @company.id) }
      let(:campaign) { create(:campaign, company_id: @company.id) }
      let(:brand) { create(:brand) }

      it 'should render success' do
        campaign.brands << brand
        xhr :get, 'select_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
        expect(assigns(:campaigns).to_a).to eql [campaign]
        expect(response).to be_success
        expect(response).to render_template('select_campaigns')
        expect(response).to render_template('_select_campaigns')
      end
    end

    describe "DELETE 'remove_campaign'" do
      let(:user) { create(:company_user, user: create(:user), company_id: @company.id) }
      let(:campaign) { create(:campaign, company_id: @company.id) }
      let(:brand) { create(:brand, company: @company) }

      it 'should remove a campaing is assigned to the user' do
        user.campaigns << campaign
        expect do
          delete 'remove_campaign', id: user.id, campaign_id: campaign.id, format: :js
          expect(response).to be_success
          user.reload
        end.to change(user.campaigns, :count).by(-1)

        expect(response).to render_template('remove_campaign')
      end

      it 'should remove a campaing is assigned to the user through a brand' do
        user.memberships.create(parent: brand, memberable: campaign)
        expect do
          delete 'remove_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          expect(response).to be_success
          user.reload
        end.to change(user.campaigns, :count).by(-1)

        expect(response).to render_template('remove_campaign')
      end

      it 'should deassign the brand from the user and assign any other campaigns that is part of this brand' do
        campaign2 = create(:campaign, company_id: @company.id)
        campaign.brands << brand
        campaign2.brands << brand

        expect(user.memberships.create(parent: brand, memberable: brand)).to be_truthy
        expect do
          delete 'remove_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          expect(response).to be_success
          user.reload
        end.to_not change(user.memberships, :count)  # Remove the parent and add the campaign2 as a member

        expect(user.memberships.map(&:memberable)).to eq([campaign2])

        expect(response).to render_template('remove_campaign')
      end
    end

    describe 'add_campaign' do
      let(:user) { create(:company_user, user: create(:user), company_id: @company.id) }
      let(:campaign) { create(:campaign, company_id: @company.id) }
      let(:brand) { create(:brand) }

      it 'should add a campaign to the user that belongs to a brand' do
        campaign.brands << brand
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{user.id}")
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{user.id}").at_least(:once)
        expect do
          xhr :post, 'add_campaign', id: user.id, parent_id: brand.id, parent_type: 'Brand', campaign_id: campaign.id, format: :js
          expect(response).to be_success
          user.reload
        end.to change(user.memberships, :count).by(1)

        expect(user.memberships.map(&:parent)).to eq([brand])
        expect(user.memberships.map(&:memberable)).to eq([campaign])
        expect(user.campaigns).to eq([campaign])
      end
    end

    describe 'disable_campaigns' do
      let(:user) { create(:company_user, user: create(:user), company_id: @company.id) }
      let(:campaign) { create(:campaign, company_id: @company.id) }
      let(:brand) { create(:brand, company: @company) }

      it 'remove the brand as a membership and assign any campaign to the user with the brand as parent' do
        campaign.brands << brand
        user.brands << brand
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{user.id}").at_least(:once)
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{user.id}").at_least(:once)
        expect do
          xhr :post, 'disable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          expect(response).to be_success
          user.reload
        end.to change(user.brands, :count).by(-1)

        expect(user.memberships.map(&:parent)).to eq([brand])
        expect(user.memberships.map(&:memberable)).to eq([campaign])
        expect(user.campaigns).to eq([campaign])
      end

      it 'should now fail if invalid parent params were provided' do
        xhr :post, 'disable_campaigns', id: user.id, parent_id: '6669999', parent_type: 'Brand', format: :js
        expect(response).to be_success
      end
    end

    describe 'enable_campaigns' do
      let(:user) { create(:company_user, user: create(:user), company_id: @company.id) }
      let(:campaign) { create(:campaign, company_id: @company.id) }
      let(:brand) { create(:brand, company: @company) }
      let(:brand_portfolio) { create(:brand_portfolio, company: @company) }

      it 'remove the brand as a membership and assign any campaign to the user with the brand as parent' do
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{user.id}")
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{user.id}").at_least(:once)
        campaign.brands << brand
        expect do
          xhr :post, 'enable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          expect(response).to be_success
          user.reload
        end.to change(user.brands, :count).by(1)

        expect(user.memberships.map(&:parent)).to eq([nil])
        expect(user.memberships.map(&:memberable)).to eq([brand])
        expect(user.campaigns).to eq([])
      end

      it 'should not create another membership if there is one already' do
        campaign.brands << brand
        user.memberships.create(memberable: brand)
        user.reload

        expect(Rails.cache).to_not receive(:delete).with("user_accessible_campaigns_#{user.id}")
        expect do
          xhr :post, 'enable_campaigns', id: user.id, parent_id: brand.id, parent_type: 'Brand', format: :js
          expect(response).to be_success
        end.to_not change(user.memberships, :count)
      end

      it 'should create a relationship between users and brand portfolio' do
        expect(Rails.cache).to receive(:delete).with("user_accessible_campaigns_#{user.id}")
        expect(Rails.cache).to receive(:delete).with("user_notifications_#{user.id}").at_least(:once)
        expect do
          xhr :post, 'enable_campaigns', id: user.id, parent_id: brand_portfolio.id, parent_type: 'BrandPortfolio', format: :js
          expect(response).to be_success
          user.reload
        end.to change(user.brand_portfolios, :count).by(1)

        expect(user.memberships.map(&:parent)).to eq([nil])
        expect(user.memberships.map(&:memberable)).to eq([brand_portfolio])
        expect(user.campaigns).to eq([])
      end
    end

    describe "GET 'list_export'", search: true do
      it 'should return a book with the correct headers and the Admin user' do
      	Sunspot.commit
        expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
        ResqueSpec.perform_all(:export)
        expect(ListExport.last).to have_rows([
          ['FIRST NAME', 'LAST NAME', 'EMAIL', 'PHONE NUMBER', 'ROLE', 'ADDRESS 1', 'ADDRESS 2',
           'CITY', 'STATE', 'ZIP CODE', 'COUNTRY', 'TIME ZONE', 'LAST LOGIN', 'ACTIVE STATE'],
          ['Test', 'User', @user.email, '+1000000000', 'Super Admin', 'Street Address 123', 'Unit Number 456',
           'Curridabat', 'SJ', '90210', 'Costa Rica', 'Pacific Time (US & Canada)', nil, 'Active']
        ])
      end

      it 'should include the results' do
        role = create(:role, name: 'TestRole', company: @company)
        create(:user, first_name: 'Pablo', last_name: 'Baltodano', email: 'email@hotmail.com',
                city: 'Los Angeles', state: 'CA', country: 'US', company: @company, role_id: role.id)
        Sunspot.commit

        expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
        expect(ListExport.last).to have_rows([
          ['FIRST NAME', 'LAST NAME', 'EMAIL', 'PHONE NUMBER', 'ROLE', 'ADDRESS 1', 'ADDRESS 2',
           'CITY', 'STATE', 'ZIP CODE', 'COUNTRY', 'TIME ZONE', 'LAST LOGIN', 'ACTIVE STATE'],
          ['Test', 'User', @user.email, '+1000000000', 'Super Admin', 'Street Address 123', 'Unit Number 456',
           'Curridabat', 'SJ', '90210', 'Costa Rica', 'Pacific Time (US & Canada)', nil, 'Active'],
          ['Pablo', 'Baltodano', 'email@hotmail.com', '+1000000000', 'TestRole', 'Street Address 123',
           'Unit Number 456', 'Los Angeles', 'CA', '90210', 'United States', 'Pacific Time (US & Canada)', nil, 'Active']
        ])
      end
    end
  end

  describe "GET 'select_custom_user'" do
      let(:user) { sign_in_as_user }
      let(:company_user) { user.company_users.first }
      let(:company) { user.company_users.first.company }

      it 'should update the session with the selected user_id' do
        role = create(:role, name: 'TestRole', company: company)
        another_user = create(:user, first_name: 'Juan', last_name: 'Perez', email: 'email@hotmail.com',
                              city: 'Los Angeles', state: 'CA', country: 'US', company: company, role_id: role.id)
        another_user_id = another_user.company_users.first.id
        get 'select_custom_user', user_id: another_user_id
        expect(session[:behave_as_user_id]).to eq(another_user.id)
        expect(response).to redirect_to root_path
      end

      describe "Login with a user not super admin" do
        let(:user) { company_user.user }
        let(:company) { create(:company) }
        let(:role) { create(:non_admin_role, company: company) }
        let(:permissions) { [[:index_results, 'Activity']] }
        let(:company_user) { create(:company_user, company: company, role: role, permissions: permissions) }

        before { sign_in_as_user company_user }

        it 'should NOT update the session with a invalid user' do
          role2 = create(:role, name: 'TestRole2', company: company)
          another_user2 = create(:user, first_name: 'Ana', last_name: 'Perez', email: 'ana@hotmail.com',
                  city: 'Los Angeles', state: 'CA', country: 'US', company: company, role_id: role.id)

          another_user2_id = another_user2.company_users.first.id
          get 'select_custom_user', user_id: another_user2_id
          expect(session[:behave_as_user_id]).to eq(nil)
          expect(response).to redirect_to root_path
        end
      end

      describe "Admin user tries to sign in as a user that is not in his company" do
        let(:user) { sign_in_as_user }
        let(:company_user) { user.company_users.first }
        let(:company) { user.company_users.first.company }
        let(:company2) { create(:company) }

        before { sign_in_as_user company_user }

        it 'should NOT update the session with a invalid user' do
          role2 = create(:role, name: 'TestRole2', company: company2)
          another_user2 = create(:user, first_name: 'Ana', last_name: 'Perez', email: 'ana@hotmail.com',
                  city: 'Los Angeles', state: 'CA', country: 'US', company: company2, role_id: role2.id)
          another_user2_id = another_user2.company_users.first.id
          get 'select_custom_user', user_id: another_user2_id

          expect(session[:behave_as_user_id]).to eq(nil)
          expect(flash[:error]).to eq('You are not allowed login as this user')
          expect(response).to redirect_to root_path
        end
      end
    end
end
