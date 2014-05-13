require 'spec_helper'

describe Results::PhotosController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'items'" do
    it "should return http success" do
      get 'items'
      response.should be_success
      response.should render_template('results/photos/items')
    end
  end

  describe "GET 'autocomplete'", search: true do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete'
      response.should be_success

      buckets = JSON.parse(response.body)
      buckets.map{|b| b['label']}.should == ['Campaigns', 'Brands', 'Places']
    end

    it "should return the campaigns in the Campaigns Bucket" do
      campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      response.should be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
      campaigns_bucket['value'].should == [{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}]
    end

    it "should return the brands in the Brands Bucket" do
      brand = FactoryGirl.create(:brand, name: 'Cacique', company_id: @company)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      response.should be_success

      buckets = JSON.parse(response.body)
      brands_bucket = buckets.select{|b| b['label'] == 'Brands'}.first
      brands_bucket['value'].should == [{"label"=>"<i>Cac</i>ique", "value"=>brand.id.to_s, "type"=>"brand"}]
    end

    it "should return the venues in the Places Bucket" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      venue = FactoryGirl.create(:venue, company_id: @company.id, place: FactoryGirl.create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'autocomplete', q: 'mot'
      response.should be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
      places_bucket['value'].should == [{"label"=>"<i>Mot</i>el Paraiso", "value"=>venue.id.to_s, "type"=>"venue"}]
    end
  end

  describe "GET 'filters'" do
    it "should return the correct buckets" do
      Sunspot.commit
      get 'filters', format: :json
      response.should be_success

      filters = JSON.parse(response.body)
      filters['filters'].map{|b| b['label']}.should == ["Campaigns", "Brands", "Areas", "Status"]
    end
  end

  describe "GET 'download'" do
    let(:attached_asset){ FactoryGirl.create(:attached_asset) }
    it "should download a photo" do
      post 'new_download', photos: [attached_asset.id], format: :js
      response.should render_template("results/photos/_download")
      response.should render_template("results/photos/new_download")
    end

    it "show show the download status" do
      asset_download = FactoryGirl.create(:asset_download)
      get "download_status", download_id: asset_download.uid, format: :json
      response.should be_success
    end
  end

end