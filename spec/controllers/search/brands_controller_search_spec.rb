require 'rails_helper'

describe BrandsController, type: :controller, search: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }

  describe "GET 'autocomplete'" do
    it 'returns the correct buckets in the right order' do
      Sunspot.commit
      get 'autocomplete'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map { |b| b['label'] }).to eq(['Brands'])
    end

    it 'returns the campaigns in the Campaigns Bucket' do
      brand = create(:brand, name: 'Cacique para todos', company: company)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select { |b| b['label'] == 'Brands' }.first
      expect(campaigns_bucket['value']).to eq([
        {
          'label' => '<i>Cac</i>ique para todos',
          'value' => brand.id.to_s, 'type' => 'brand'
        }])
    end
  end

  describe "GET 'filters'" do
    it 'should return the correct filters in the right order' do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map { |b| b['label'] }).to eq(['Active State'])
    end
  end
end
