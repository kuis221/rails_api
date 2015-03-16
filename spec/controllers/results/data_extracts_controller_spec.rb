require 'rails_helper'

RSpec.describe Results::DataExtractsController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_select_data_source')
    end
    it 'Not select data source' do
      xhr :get, 'new', step: '2', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_select_data_source')
    end
    it 'select data source' do
      xhr :get, 'new', step: '2', data_source: 'event', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_configure')
    end
  end
end
