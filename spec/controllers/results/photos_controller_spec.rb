require 'rails_helper'

describe Results::PhotosController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it "should return http success" do
      get 'items'
      expect(response).to be_success
      expect(response).to render_template('results/photos/items')
    end
  end

  describe "GET 'autocomplete'", search: true do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map{|b| b['label']}).to eq(['Campaigns', 'Brands', 'Places'])
    end

    it "should return the campaigns in the Campaigns Bucket" do
      campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
      expect(campaigns_bucket['value']).to eq([{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}])
    end

    it "should return the brands in the Brands Bucket" do
      brand = FactoryGirl.create(:brand, name: 'Cacique', company_id: @company)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      brands_bucket = buckets.select{|b| b['label'] == 'Brands'}.first
      expect(brands_bucket['value']).to eq([{"label"=>"<i>Cac</i>ique", "value"=>brand.id.to_s, "type"=>"brand"}])
    end

    it "should return the venues in the Places Bucket" do
      expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
      venue = FactoryGirl.create(:venue, company_id: @company.id, place: FactoryGirl.create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'autocomplete', q: 'mot'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
      expect(places_bucket['value']).to eq([{"label"=>"<i>Mot</i>el Paraiso", "value"=>venue.id.to_s, "type"=>"venue"}])
    end
  end

  describe "GET 'filters'" do
    it "should return the correct buckets" do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map{|b| b['label']}).to eq(["Campaigns", "Brands", "Areas", "Status"])
    end
  end

  describe "GET 'download'" do
    let(:attached_asset){ FactoryGirl.create(:attached_asset, attachable: FactoryGirl.create(:event, company: @company)) }
    it "should download a photo" do
      xhr :post, 'new_download', photos: [attached_asset.id], format: :js
      expect(response).to render_template("results/photos/_download")
      expect(response).to render_template("results/photos/new_download")
    end

    it "show show the download status" do
      asset_download = FactoryGirl.create(:asset_download)
      get "download_status", download_id: asset_download.uid, format: :json
      expect(response).to be_success
    end
  end

end