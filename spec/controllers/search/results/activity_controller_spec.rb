require 'rails_helper'

describe Results::ActivitiesController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
    Sunspot.commit
  end

  describe "GET 'filters'" do
    it 'should return the correct filters in the right order' do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map { |b| b['label'] }).to eq(['Activity Types', 'Brands', 'Campaigns', 'Areas', 'Users', 'Active State'])
    end
  end
end