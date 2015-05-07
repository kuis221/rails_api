require 'rails_helper'

RSpec.describe Api::V1::FiltersController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  before { set_api_authentication_headers user, company }

  describe "GET 'show'" do
    it 'returns the events filters', :show_in_doc do
      create_list(:campaign, 2, company: company)
      create_list(:area, 2, company: company)
      create_list(:brand, 2, company: company)
      create_list(:team, 2, company: company)
      get :show, id: :events, format: :json
      expect(response).to be_success
      expect(json.keys).to eq(%w(filters))
    end

    it 'returns the venues filters', :search do
      get :show, id: :venues, format: :json
      expect(response).to be_success
      expect(json.keys).to eq(%w(filters))
    end

    it 'returns the visits' do
      get :show, id: :visits, format: :json
      expect(response).to be_success
      expect(json.keys).to eq(%w(filters))
    end
  end
end
