require 'rails_helper'

RSpec.describe BrandAmbassadors::DashboardController, type: :controller do

  describe 'GET :index' do
    let(:company) { create(:company) }
    let(:user) { create(:company_user, company: company) }

    before { sign_in_as_user user }

    it 'returns http success' do
      get :index
      expect(response).to be_success
    end

    it "assigns the current company's visits to @visits" do
      expected_visits = create_list(:brand_ambassadors_visit, 3, company: company)
      create_list(:brand_ambassadors_visit, 2, company: create(:company))
      get :index
      expect(assigns(:visits)).to match_array(expected_visits)
    end
  end

end
