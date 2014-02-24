require 'spec_helper'

describe Api::V1::PhotosController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  describe "GET 'index'", search: true do
    it "return a list of photos" do
      campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place)
      event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
      photos = FactoryGirl.create_list(:photo, 3, attachable: event)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result['results'].count.should == 3
      result['total'].should == 3
      result['page'].should == 1
      result['results'].first.keys.should =~ ["id", "file_content_type", "file_file_name", "file_file_size", "created_at", "active", "file_medium", "file_thumbnail", "file_original", "file_small"]
    end

    it "return a list of photos filtered by brand id" do
      brand = FactoryGirl.create(:brand, name: 'Imperial')
      other_brand = FactoryGirl.create(:brand, name: 'Pilsen')
      campaign = FactoryGirl.create(:campaign, company: company, brand_ids: [brand.id])
      place = FactoryGirl.create(:place)
      event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
      other_event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
      photos = FactoryGirl.create_list(:photo, 4, attachable: event)
      other_photos = FactoryGirl.create_list(:photo, 3, attachable: other_event)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, brand: [brand.id], format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result['results'].count.should == 4
    end

    it "return a list of photos filtered by place id" do
      campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place)
      other_place = FactoryGirl.create(:place)
      event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
      other_event = FactoryGirl.create(:event, company: company, campaign: campaign, place: other_place)
      photos = FactoryGirl.create_list(:photo, 5, attachable: event)
      other_photos = FactoryGirl.create_list(:photo, 3, attachable: other_event)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, place_id: [place.id], format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result['results'].count.should == 5
    end

    it "return a list of active photos filtered by status" do
      campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place)
      event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
      active_photos = FactoryGirl.create_list(:photo, 6, attachable: event, active: true)
      inactive_photos = FactoryGirl.create_list(:photo, 3, attachable: event, active: false)

      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, status: ['Active'], format: :json
      response.should be_success
      result = JSON.parse(response.body)

      result['results'].count.should == 6
    end
  end

  describe "POST 'create'", strategy: :deletion  do
    let(:event) {FactoryGirl.create(:event, company: company, campaign: FactoryGirl.create(:campaign, company: company))}
    it "queue a job for processing the photos" do
      ResqueSpec.reset!
      AWS::S3.any_instance.should_receive(:buckets).and_return("brandscopic-test" => double(objects: {'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now))}))
      expect {
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, event_id: event.to_param, attached_asset: {direct_upload_url: 'https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg'}, format: :json
      }.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('show')
      photo = AttachedAsset.last
      photo.attachable.should == event
      photo.asset_type.should == 'photo'
      photo.direct_upload_url.should == 'https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg'
      AssetsUploadWorker.should have_queued(photo.id)
    end
  end
end