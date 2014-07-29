require 'spec_helper'

describe InvitationsController, :type => :controller do
  describe "as registered user" do
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = sign_in_as_user
      @company = @user.current_company
    end

    describe "GET 'new'" do
      it "returns http success" do
        get 'new', format: :js
        expect(response).to be_success
        expect(response).to render_template('new')
        expect(response).to render_template('form')
      end

      it "builds a new company user relationship on user" do
        get 'new', format: :js
        expect(assigns(:user).new_record?).to be_truthy
        expect(assigns(:user).company_users.any?).to be_truthy
        expect(assigns(:user).company_users.first.new_record?).to be_truthy
      end
    end

    describe "POST 'create'" do
      it "should not render form_dialog if no errors" do
        expect {
          post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com', company_users_attributes: {"0" => {role_id: 1}}}, format: :js
        }.to change(User, :count).by(1)
        expect(response).to be_success
        expect(response).to render_template(:create)
        expect(response).not_to render_template(:form_dialog)
      end

      it "should render the form_dialog template if errors" do
        expect {
          post 'create', user: {}, format: :js
        }.not_to change(User, :count)
        expect(response).to render_template(:create)
        expect(response).to render_template(:form_dialog)
        assigns(:user).errors.count > 0
      end

      it "should assign current_user's company_id to the new user" do
        expect {
          expect {
            post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com', company_users_attributes: {"0" => {role_id: 123}}}, format: :js
          }.to change(User, :count).by(1)
        }.to change(CompanyUser, :count).by(1)
        expect(assigns(:user).companies.count).to eq(1)
        expect(assigns(:user).companies.first.id).to eq(@company.id)
        expect(assigns(:user).company_users.first.role_id).to eq(123)
      end


      it "should require the role_id" do
        expect {
          expect {
            post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com', company_users_attributes: {}}, format: :js
          }.not_to change(User, :count)
        }.not_to change(CompanyUser, :count)
        expect(assigns(:user).company_users.first.errors[:role_id]).to eq(["can't be blank", "is not a number"])
      end

      it "should not send a company invitation email if the user doesnt exist on the app" do
        expect(UserMailer).not_to receive(:company_invitation)
        expect {
          expect {
            post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com', company_users_attributes: {"0" => {role_id: 123}}}, format: :js
          }.to change(User, :count).by(1)
        }.to change(CompanyUser, :count).by(1)
      end

      describe "when a user with the same email already exists" do
        it "should associate the user to the current company without updating it's attributes" do
          user = FactoryGirl.create(:user,first_name: 'Tarzan', last_name: 'de la Selva', company_id: 987)
          expect{
            expect {
              post 'create', user: {first_name: 'Ignored Name', last_name: 'Ignored Last', email: user.email, company_users_attributes: {"0" => {role_id: 1}}}, format: :js
              expect(assigns(:user).errors.empty?).to be_truthy
            }.not_to change(User, :count)
          }.to change(CompanyUser, :count).by(1)
          expect(user.reload.first_name).to eq('Tarzan')
          expect(user.last_name).to eq('de la Selva')
          expect(user.company_users.count).to eq(2)
        end

        it "should send a company invitation email" do
          user = FactoryGirl.create(:user, company_id: 987)
          expect(UserMailer).to receive(:company_invitation).with(user, @company, @user).and_return(double(deliver: true))
          post 'create', user: {first_name: 'Some name', last_name: 'Last', email: user.email, company_users_attributes: {"0" => {role_id: 1}}}, format: :js
        end

        it "should not reassign the user to the same company" do
          user = FactoryGirl.create(:user, email: 'existingemail4321@gmail.com', company_id: @company.id)
          expect {
            expect {
              post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'existingemail4321@gmail.com', company_users_attributes: {"0" => {role_id: 123}}}, format: :js
            }.not_to change(User, :count)
          }.not_to change(CompanyUser, :count)
          expect(assigns(:user).company_users.size).to eq(1)
          expect(assigns(:user).errors[:email]).to eq(["This user with the email address existingemail4321@gmail.com already exists. Email addresses must be unique."])
        end
      end
    end
  end


  describe('as a invited user') do
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @company = FactoryGirl.create(:company)
    end
    let(:user){ FactoryGirl.create(:invited_user, company_id: @company.id, role_id: FactoryGirl.create(:role).id) }

    describe "POST 'send_invite'" do
      it "ask for resending the invitation's instructions" do
        post 'send_invite', user: {email: user.email}
        expect(response).to render_template('devise/mailer/invitation_instructions')
        expect(response).to redirect_to new_user_session_path
      end

      it "ask for resending the invitation's instructions with empty email" do
        post 'send_invite', user: {email: ''}
        expect(response).to redirect_to users_invitation_resend_path
      end
    end

    describe "GET 'edit'" do
      it "should accept a company invitation email" do
        get 'edit', invitation_token: user.invitation_token, format: :js
        expect(response).to be_success
      end
    end

    describe "PUT 'update'" do
      it "must update the user attributes" do
        put 'update', user: {accepting_invitation: true, first_name: 'Juanito', last_name: 'Perez', phone_number: '(506)22124578', city: 'Miami', state: 'FL', country: 'US', street_address: 'Street Address 123', unit_number: 'Unit Number 456', zip_code: '90210', time_zone: 'American Samoa', password: 'zddjadasidasdASD123', password_confirmation: 'zddjadasidasdASD123', invitation_token: user.invitation_token}
        expect(response).to redirect_to(root_path)
        user.reload
        expect(user.first_name).to eq('Juanito')
        expect(user.last_name).to eq('Perez')
        expect(user.city).to eq('Miami')
        expect(user.state).to eq('FL')
        expect(user.country).to eq('US')
        expect(user.street_address).to eq('Street Address 123')
        expect(user.unit_number).to eq('Unit Number 456')
        expect(user.zip_code).to eq('90210')
        expect(user.time_zone).to eq('American Samoa')
        expect(user.invitation_token).to be_nil
        expect(user.invitation_accepted_at.to_date).to eq(Time.zone.now.to_date)
        expect(flash[:notice]).to eq('Your password was set successfully. You are now signed in.')
      end

      it "must require the user location attributes" do
        put 'update', user: {accepting_invitation: true, first_name: 'Juanito', last_name: 'Perez', city: '', state: '', country: '', street_address: '', zip_code: '', password: 'zddjadasidasdASD123', password_confirmation: 'zddjadasidasdASD123', invitation_token: user.invitation_token}
        user.reload
        expect(assigns(:user).errors.count).to be > 0
        expect(assigns(:user).errors[:country]).to eq(["can't be blank"])
        expect(assigns(:user).errors[:state]).to eq(["can't be blank"])
        expect(assigns(:user).errors[:city]).to eq(["can't be blank"])
        expect(assigns(:user).errors[:street_address]).to eq(["can't be blank"])
        expect(assigns(:user).errors[:zip_code]).to eq(["can't be blank"])
      end

      it "must require the password" do
        put 'update', user: {accepting_invitation: true, first_name: 'Juanito', last_name: 'Perez', city: 'Miami', state: 'FL', country: 'US', password: '', password_confirmation: '', invitation_token: user.invitation_token}
        user.reload
        expect(assigns(:user).errors.count).to be > 0
        expect(assigns(:user).errors[:password]).to eq(["can't be blank"])
      end
    end
  end
end