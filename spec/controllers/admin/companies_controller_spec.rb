require 'spec_helper'

describe Admin::CompaniesController do
  before do
    @user = FactoryGirl.create(:admin_user)
    sign_in @user
  end

  let(:company) { FactoryGirl.create(:company) }

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get :new
      response.should be_success
      assigns(:company).new_record?.should be_true
    end
  end

  describe "POST 'create'" do
    it "creates the new company" do
      expect{
        post :create, company: {name: 'Company 1', admin_email: "testemail@brandscopic.com"}
      }.to change(Company, :count).by(1)

      company = Company.last
      response.should redirect_to(admin_company_path(company))

      company.name.should == 'Company 1'
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: company.to_param
      response.should be_success
      assigns(:company).should == company
    end
  end

  describe "PUT 'update'" do
    it "returns http success" do
      put 'update', id: company.to_param, company: {name: 'New Name'}
      response.should redirect_to(admin_company_path(company))
      assigns(:company).should == company
      company.reload.name.should == 'New Name'
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      #p company.inspect
      get 'show', id: company.to_param
      response.should be_success
      assigns(:company).should == company
    end
  end

end