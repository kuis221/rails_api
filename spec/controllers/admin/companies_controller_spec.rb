require 'spec_helper'

describe Admin::CompaniesController, :type => :controller do
  before do
    @user = FactoryGirl.create(:admin_user)
    sign_in @user
  end

  let(:company) { FactoryGirl.create(:company) }

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get :new
      expect(response).to be_success
      expect(assigns(:company).new_record?).to be_truthy
    end
  end

  describe "POST 'create'" do
    let(:creating_a_new_company) { -> { post :create, company: {name: 'Company 1', admin_email: "testemail@brandscopic.com"} } }

    it "changes the Companies count" do
      expect(creating_a_new_company).to change(Company, :count).by(1)

      company = Company.last
      expect(response).to redirect_to(admin_company_path(company))
      expect(company.name).to eq('Company 1')
    end

    it "changes the Roles count" do
      expect(creating_a_new_company).to change(Role, :count).by(1)

      role = Role.last
      expect(role.name).to eq('Super Admin')
      expect(role.is_admin).to eq(true)
      expect(role.company_id).to eq(Company.last.id)
    end

    it "changes the Users count" do
      expect(creating_a_new_company).to change(User, :count).by(1)

      user = User.last
      expect(user.first_name).to eq('Admin')
      expect(user.last_name).to eq('User')
      expect(user.email).to eq('testemail@brandscopic.com')
    end

    it "changes the Company Users count" do
      expect(creating_a_new_company).to change(CompanyUser, :count).by(1)

      company_user = CompanyUser.last
      expect(company_user.active).to eq(true)
      expect(company_user.user_id).to eq(User.last.id)
      expect(company_user.role_id).to eq(Role.last.id)
    end

    it "doesn't change the Users count when it already exists and include the new company in the user companies list" do
      existing_user = FactoryGirl.create(:user, first_name: 'Admin', last_name: 'User', email: 'testemail@brandscopic.com')

      expect {
        expect(creating_a_new_company).to_not change(User, :count)
      }.to change(CompanyUser, :count).by(1)

      company_user = CompanyUser.last
      expect(company_user.user_id).to eql existing_user.id
      expect(existing_user.company_users).to include company_user
    end

    it "doesn't include the new company in the user companies list when required attributes are not present" do
      existing_user = FactoryGirl.create(:user, first_name: 'Admin', last_name: 'User', email: 'testemail@brandscopic.com')
      existing_user.phone_number = nil
      existing_user.street_address = nil
      existing_user.save validate: false

      expect {
        expect(creating_a_new_company).to_not change(User, :count)
      }.to change(CompanyUser, :count).by(1)

      company_user = CompanyUser.last
      expect(company_user.user_id).to eql existing_user.id
      expect(existing_user.company_users).to include company_user
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: company.to_param
      expect(response).to be_success
      expect(assigns(:company)).to eq(company)
    end
  end

  describe "PUT 'update'" do
    it "returns http success" do
      put 'update', id: company.to_param, company: {name: 'New Name'}
      expect(response).to redirect_to(admin_company_path(company))
      expect(assigns(:company)).to eq(company)
      expect(company.reload.name).to eq('New Name')
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      #p company.inspect
      get 'show', id: company.to_param
      expect(response).to be_success
      expect(assigns(:company)).to eq(company)
    end
  end

end