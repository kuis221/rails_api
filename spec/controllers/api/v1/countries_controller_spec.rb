require 'rails_helper'

describe Api::V1::CountriesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  before { set_api_authentication_headers user, company }

  describe '#index' do
    it 'returns a list of countries' do
      get 'index', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to include('id' => 'US', 'name' => 'United States')
    end
  end

  describe '#states' do
    it 'returns a list of countries' do
      get 'states', id: 'US', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to include('id' => 'CA', 'name' => 'California')
    end
  end
end
