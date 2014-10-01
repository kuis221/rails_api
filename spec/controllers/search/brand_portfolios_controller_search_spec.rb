require 'rails_helper'

describe BrandPortfoliosController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'autocomplete'" do
    it 'should return the correct buckets in the right order' do
      Sunspot.commit
      get 'autocomplete'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map { |b| b['label'] }).to eq(['Brands'])
    end

    it 'should return the brands in the Brands Bucket' do
      brand = create(:brand, name: 'Cacique', company_id: @company)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      brands_bucket = buckets.select { |b| b['label'] == 'Brands' }.first
      expect(brands_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
    end
  end

  describe "GET 'filters'" do
    it 'should return the correct filters in the right order' do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map { |b| b['label'] }).to eq(['Brands', 'Active State'])
    end
  end
end
