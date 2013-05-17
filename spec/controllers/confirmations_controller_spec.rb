require 'spec_helper'

describe ConfirmationsController do
  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
      @user = sign_in_as_user
      @company = @user.companies.first
    end

    describe "GET 'show'" do
      let(:user){ FactoryGirl.create(:unconfirmed_user, company_id: @company.id) }
      it "should redirect to root path with a warning" do
        get 'show', confirmation_token: user.confirmation_token
        assigns(:resource).should == user
        response.should be_success
        response.should render_template('show')
      end
    end

    describe "PUT 'update'" do
      let(:user){ FactoryGirl.create(:unconfirmed_user, company_id: @company.id) }
      it "must update the user attributes" do
        put 'update', confirmation_token: user.confirmation_token, user: {first_name: 'Juanito', last_name: 'Perez', city: 'Miami', state: 'FL', country: 'US', password: 'zddjadasidasdASD123', password_confirmation: 'zddjadasidasdASD123'}
        assigns(:resource).should == user
        response.should redirect_to(root_path)
        user.reload
        user.first_name.should == 'Juanito'
        user.last_name.should == 'Perez'
        user.city.should == 'Miami'
        user.state.should == 'FL'
        user.country.should == 'US'
        user.confirmed?.should be_true
      end
    end
end