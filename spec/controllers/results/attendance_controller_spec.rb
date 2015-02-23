require 'rails_helper'

describe Results::AttendanceController, type: :controller do

  let(:user) { company_user.user }
  let(:company) { create(:company) }
  let(:role) { create(:non_admin_role, company: company) }
  let(:permissions) { [[:index_results, 'Activity']] }
  let(:company_user) { create(:company_user, company: company, role: role, permissions: permissions) }

  before { sign_in_as_user company_user }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response).to be_success
    end
  end

  describe 'GET map' do
    it 'returns http success' do
      xhr :get, :map, city: 'Los Angeles', state: 'CA', format: :js
      expect(response).to be_success
    end

    it 'loads the correct set of neighborhoods' do
      neighborhoods = [
        create(:neighborhood,  city: 'Los Angeles', state: 'CA'),
        create(:neighborhood, city: 'Los Angeles', state: 'CA')
      ]
      create(:neighborhood, city: 'San Francisco', state: 'CA')

      xhr :get, :map, city: 'Los Angeles', state: 'CA', format: :js

      expect(assigns(:neighborhoods)).to match_array neighborhoods
    end
  end

end
