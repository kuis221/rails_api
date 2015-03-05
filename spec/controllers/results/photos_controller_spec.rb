require 'rails_helper'

describe Results::PhotosController, type: :controller, search: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it 'should return http success' do
      get 'items'
      expect(response).to be_success
      expect(response).to render_template('results/photos/items')
    end
  end

  describe "GET 'filters'" do
    it 'should return the correct buckets' do
      create(:custom_filter, owner: company_user, apply_to: 'results_photos')
      Sunspot.commit
      get 'filters', apply_to: :results_photos, format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map { |b| b['label'] }).to eq([
        'Campaigns', 'Brands', 'Areas', 'Tags', 'Star Rating', 'Status'])
    end
  end

  describe "GET 'download'" do
    let(:attached_asset) { create(:attached_asset, attachable: create(:event, company: company)) }
    it 'should download a photo' do
      xhr :post, 'new_download', photos: [attached_asset.id], format: :js
      expect(response).to render_template('results/photos/_download')
      expect(response).to render_template('results/photos/new_download')
    end

    it 'show show the download status' do
      asset_download = create(:asset_download)
      get 'download_status', download_id: asset_download.uid, format: :json
      expect(response).to be_success
    end
  end

end
