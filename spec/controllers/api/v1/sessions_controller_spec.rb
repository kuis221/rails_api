require 'spec_helper'

describe Api::V1::SessionsController, :type => :controller do
  describe "POST create" do
    let(:user) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, password: 'PassDePrueba45', password_confirmation: 'PassDePrueba45'), company: FactoryGirl.create(:company) ).user }
    let(:company) { user.companies.first }
    it "should return the authentication token if success" do
      expect(user.reload.current_company_id).to be_nil
      post :create, email: user.email, password: 'PassDePrueba45', format: :json
      expect(user.reload.authentication_token).to_not be_nil
      result = JSON.parse(response.body)
      expect(response).to be_success
      expect(result['success']).to be_truthy
      expect(result['info']).to eq('Logged in')
      expect(result['data']['auth_token']).to eq(user.authentication_token)
      expect(result['data']['current_company_id']).to eq(company.id)

      # It should set the current_company_id if nil
      expect(user.reload.current_company_id).to eql user.companies.first.id
    end

    it "should return the current_company_id" do
      # Add the user to another company
      other_company = FactoryGirl.create(:company_user, user: user, company_id: FactoryGirl.create(:company).id).company
      user.update_column(:current_company_id, other_company.id)

      post :create, email: user.email, password: 'PassDePrueba45', format: :json
      result = JSON.parse(response.body)
      expect(response).to be_success
      expect(result['success']).to be_truthy
      expect(result['data']['current_company_id']).to eq(other_company.id)
    end

    it "should fix the current_company_id if not valid" do
      user.update_column(:current_company_id, company.id+100)

      post :create, email: user.email, password: 'PassDePrueba45', format: :json
      result = JSON.parse(response.body)
      expect(response).to be_success
      expect(result['success']).to be_truthy
      expect(result['data']['current_company_id']).to eq(company.id)
    end

    it "should return an error if not success" do
      post :create, email: user.email, password: 'XXXXXXXX', format: :json
      result = JSON.parse(response.body)
      expect(response.response_code).to eq(401)
      expect(result['success']).to be_falsey
      expect(result['info']).to eq('Login Failed')
      expect(result['data']).to eq({})
    end
  end

  describe "DELETE 'destroy'" do
    let(:user) { FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, password: 'PassDePrueba45', password_confirmation: 'PassDePrueba45', authentication_token: 'XYZ') ).user }

    it "should reset the authentication token" do
      delete :destroy, id: user.authentication_token, format: :json
      expect(response).to be_success
      user.reload
      expect(user.authentication_token).not_to eq('XYZ')
    end

    it "return 404 if the authentication token is not found" do
      delete :destroy, id: 'NOT_VALID', format: :json
      expect(response.response_code).to eq(404)
      result = JSON.parse(response.body)
      expect(result["sucess"]).to be_falsey
      expect(result["info"]).to eq("Invalid token.")
    end
  end
end