require 'rails_helper'

describe Api::V1::PhotosController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign, company: company, modules: { 'photos' => {} }) }

  describe "GET 'index'", search: true do
    it 'return a list of photos' do
      place = create(:place)
      event = create(:event, company: company, campaign: campaign, place: place)
      photos = create_list(:photo, 3, attachable: event)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(3)
      expect(result['total']).to eq(3)
      expect(result['page']).to eq(1)
      expect(result['results'].first.keys).to match_array(%w(id file_content_type file_file_name file_file_size created_at active file_medium file_thumbnail file_original file_small))
    end

    it 'return a list of photos filtered by brand id' do
      brand = create(:brand, name: 'Imperial')
      other_brand = create(:brand, name: 'Pilsen')
      campaign = create(:campaign, company: company, brand_ids: [brand.id])
      place = create(:place)
      event = create(:event, company: company, campaign: campaign, place: place)
      other_event = create(:event, company: company, campaign: campaign, place: place)
      photos = create_list(:photo, 4, attachable: event)
      other_photos = create_list(:photo, 3, attachable: other_event)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, brand: [brand.id], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(4)
    end

    it 'return a list of photos filtered by place id' do
      place = create(:place)
      other_place = create(:place)
      event = create(:event, company: company, campaign: campaign, place: place)
      other_event = create(:event, company: company, campaign: campaign, place: other_place)
      photos = create_list(:photo, 5, attachable: event)
      other_photos = create_list(:photo, 3, attachable: other_event)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, place_id: [place.id], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(5)
    end

    it 'return a list of active photos filtered by status' do
      place = create(:place)
      event = create(:event, company: company, campaign: campaign, place: place)
      active_photos = create_list(:photo, 6, attachable: event, active: true)
      inactive_photos = create_list(:photo, 3, attachable: event, active: false)

      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, event_id: event.id, status: ['Active'], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(6)
    end
  end

  describe "POST 'create'", strategy: :deletion  do
    let(:event) { create(:event, company: company, campaign: campaign) }
    it 'queue a job for processing the photos' do
      ResqueSpec.reset!
      s3object = double
      allow(s3object).to receive(:copy_from).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        'brandscopic-dev' => double(objects: {
                                      'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now)),
                                      'attached_assets/original/test.jpg' => s3object
                                    }))
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).at_least(:once).and_return('/attached_assets/original/test.jpg')
      expect do
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, event_id: event.to_param, attached_asset: { direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg' }, format: :json
      end.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('show')
      photo = AttachedAsset.last
      expect(photo.attachable).to eq(event)
      expect(photo.asset_type).to eq('photo')
      expect(photo.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(photo.id, 'AttachedAsset')
    end
  end

  describe "GET 'form'" do
    it 'returns the required information' do
      event = create(:event, company: company, campaign: campaign)
      Sunspot.commit

      get :form, company_id: company.to_param, auth_token: user.authentication_token, event_id: event.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.keys).to match_array(%w(fields url))
      expect(result['fields'].keys).to match_array(%w(AWSAccessKeyId Secure key policy signature acl success_action_status))
    end
  end
end
