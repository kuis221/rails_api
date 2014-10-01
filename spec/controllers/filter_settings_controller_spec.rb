require 'rails_helper'

describe FilterSettingsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.company_users.first
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', company_user_id: @company_user.to_param, apply_to: 'events', filters_labels: %w(Campaigns Brands Areas Users Teams), format: :js
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it 'should be able to create a filters settings' do
      expect do
        xhr :post, 'create', filter_setting: { company_user_id: @company_user.to_param, apply_to: 'events', settings: %w(campaigns_events_active brands_events_active) }, format: :js
      end.to change(FilterSetting, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('create')
      expect(response).not_to render_template('_form_dialog')
      filter_setting = FilterSetting.last
      expect(filter_setting.company_user_id).to eq(@company_user.id)
      expect(filter_setting.apply_to).to eq('events')
      expect(filter_setting.settings).to match_array %w(campaigns_events_active brands_events_active)
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', filter_setting: { company_user_id: @company_user.to_param, apply_to: '', settings: '' }, filters_labels: %w(Campaigns Brands), format: :js
      end.not_to change(FilterSetting, :count)
      expect(response).to render_template('create')
      expect(response).to render_template('_form_dialog')
      assigns(:filter_setting).errors.count > 0
    end
  end

  describe "PATCH 'update'" do
    let(:filter_setting) { create(:filter_setting, company_user_id: @company_user.to_param, apply_to: 'events', settings: %w(campaigns_events_active brands_events_active)) }
    it 'should be able to update the existing filters settings' do
      xhr :put, 'update', id: filter_setting.to_param, filter_setting: { company_user_id: @company_user.to_param, apply_to: 'events', settings: %w(teams_events_active teams_events_inactive) }, format: :js
      expect(assigns(:filter_setting)).to eq(filter_setting)
      expect(response).to be_success
      filter_setting.reload
      expect(filter_setting.company_user_id).to eq(@company_user.id)
      expect(filter_setting.apply_to).to eq('events')
      expect(filter_setting.settings).to match_array %w(teams_events_active teams_events_inactive)
    end
  end
end
