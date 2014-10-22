require 'rails_helper'

describe Api::V1::ApiController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }

  controller(Api::V1::ApiController) do
    skip_authorize_resource
    skip_authorization_check
    skip_load_and_authorize_resource
    def index
    end

    def show
      fail ActiveRecord::RecordNotFound
    end
  end

  describe 'handling InvalidAuthToken exception' do
    it 'renders failure HTTP Unauthorized' do
      set_api_authentication_headers build(:user, authentication_token: 'XXXXX'), company
      get :index, format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Invalid auth token')
      expect(result['data']).to be_empty
    end
  end

  describe 'handling InvalidCompany exception' do
    it 'renders failure HTTP Unauthorized' do
      set_api_authentication_headers user, create(:company)
      get :index, format: :json
      expect(response.response_code).to eq(401)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Invalid company')
      expect(result['data']).to be_empty
    end
  end

  describe 'handling RecordNotFound exception' do
    it 'renders failure HTTP Not Found' do
      get :show, id: 1, format: :json
      expect(response.response_code).to eq(404)
      result = JSON.parse(response.body)
      expect(result['success']).to eq(false)
      expect(result['info']).to eq('Record not found')
      expect(result['data']).to be_empty
    end
  end
end
