require 'spec_helper'

describe InvitationsController do
  describe "as registered user" do
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = sign_in_as_user
      @company = @user.current_company
    end

    describe "POST 'create'" do
      it "returns http success" do
        post 'create', user: {}, format: :js
        response.should be_success
      end

      it "should not render form_dialog if no errors" do
        lambda {
          post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com', company_users_attributes: {"0" => {role_id: 1}}}, format: :js
        }.should change(User, :count).by(1)
        response.should be_success
        response.should render_template(:create)
        response.should_not render_template(:form_dialog)
      end

      it "should render the form_dialog template if errors" do
        lambda {
          post 'create', user: {}, format: :js
        }.should_not change(User, :count)
        response.should render_template(:create)
        response.should render_template(:form_dialog)
        assigns(:user).errors.count > 0
      end

      it "should assign current_user's company_id to the new user" do
        lambda {
          lambda {
            post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com', company_users_attributes: {"0" => {role_id: 123}}}, format: :js
          }.should change(User, :count).by(1)
        }.should change(CompanyUser, :count).by(1)
        assigns(:user).companies.count.should == 1
        assigns(:user).companies.first.id.should == @company.id
        assigns(:user).company_users.first.role_id.should == 123
      end


      it "should require the role_id" do
        lambda {
          lambda {
            post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com'}, format: :js
          }.should_not change(User, :count)
        }.should_not change(CompanyUser, :count)
        assigns(:user).company_users.first.errors[:role_id].should == ["can't be blank", "is not a number"]
      end

      it "should not send a company invitation email if the user doesnt exist on the app" do
        UserMailer.should_not_receive(:company_invitation)
        lambda {
          lambda {
            post 'create', user: {first_name: 'Test', last_name: 'Test', email: 'test@testing.com', company_users_attributes: {"0" => {role_id: 123}}}, format: :js
          }.should change(User, :count).by(1)
        }.should change(CompanyUser, :count).by(1)
      end

      describe "when a user with the same email already exists" do
        it "should associate the user to the current company without updating it's attributes" do
          user = FactoryGirl.create(:user,first_name: 'Tarzan', last_name: 'de la Selva', company_id: 987)
          lambda{
            lambda {
              post 'create', user: {first_name: 'Ignored Name', last_name: 'Ignored Last', email: user.email, company_users_attributes: {"0" => {role_id: 1}}}, format: :js
              assigns(:user).errors.empty?.should be_true
            }.should_not change(User, :count)
          }.should change(CompanyUser, :count).by(1)
          user.reload.first_name.should == 'Tarzan'
          user.last_name.should == 'de la Selva'
          user.company_users.count.should == 2
        end

        it "should send a company invitation email" do
          user = FactoryGirl.create(:user, company_id: 987)
          UserMailer.should_receive(:company_invitation).with(user, @company, @user).and_return(double(deliver: true))
          post 'create', user: {first_name: 'Some name', last_name: 'Last', email: user.email, company_users_attributes: {"0" => {role_id: 1}}}, format: :js
        end

        it "should not reassign the user to the same company" do
          user = FactoryGirl.create(:user,first_name: 'Tarzan', last_name: 'de la Selva', company_id: @company.id)
          lambda {
            lambda {
              post 'create', user: {first_name: 'Test', last_name: 'Test', email: user.email, company_users_attributes: {"0" => {role_id: 123}}}, format: :js
            }.should_not change(User, :count)
          }.should_not change(CompanyUser, :count)
        end
      end
    end
  end


  describe('as a invited user') do
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      @company = FactoryGirl.create(:company)
    end

    describe "PUT 'update'" do
      let(:user){ FactoryGirl.create(:invited_user, company_id: @company.id, role_id: FactoryGirl.create(:role).id) }
      it "must update the user attributes" do
        put 'update', user: {first_name: 'Juanito', last_name: 'Perez', city: 'Miami', state: 'FL', country: 'US', password: 'zddjadasidasdASD123', password_confirmation: 'zddjadasidasdASD123', invitation_token: user.invitation_token}
        response.should redirect_to(root_path)
        user.reload
        user.first_name.should == 'Juanito'
        user.last_name.should == 'Perez'
        user.city.should == 'Miami'
        user.state.should == 'FL'
        user.country.should == 'US'
        user.invitation_token.should be_nil
        user.invitation_accepted_at.to_date.should == Date.today
        flash[:notice].should == 'Your password was set successfully. You are now signed in.'
      end
    end
  end
end