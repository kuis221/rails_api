require 'rails_helper'

RSpec.describe Results::DataExtractsController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  let(:data_extract) { create(:data_extract) }

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_select_data_source')
    end
    it 'Not select data source' do
      xhr :get, 'new', step: 2, data_extract: {source: ''}, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_configure')
    end
    it 'select data source' do
      xhr :get, 'new', step: 2, data_extract: {source: 'event'}, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_configure')
    end
  end

  describe "GET 'deactivate'" do
    it 'deactivates an active data extract report' do
      data_extract.update_attribute(:active, true)
      xhr :get, 'deactivate', id: data_extract.to_param, format: :js
      expect(response).to be_success
      expect(data_extract.reload.active?).to be_falsey
    end

    it 'activates an inactive report' do
      data_extract.update_attribute(:active, false)
      xhr :get, 'activate', id: data_extract.to_param, format: :js
      expect(response).to be_success
      expect(data_extract.reload.active?).to be_truthy
    end
  end
end
