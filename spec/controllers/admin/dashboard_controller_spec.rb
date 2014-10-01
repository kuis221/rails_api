require 'rails_helper'

describe Admin::DashboardController, type: :controller do
  before do
    @user = create(:admin_user)
    sign_in @user
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end
  end
end
