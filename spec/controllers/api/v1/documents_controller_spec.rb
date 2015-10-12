require 'rails_helper'

describe Api::V1::DocumentsController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign, company: company, modules: { 'photos' => {} }) }

  before { set_api_authentication_headers user, company }

  describe "GET 'index'" do
    it 'return a list of documents', :show_in_doc do
      place = create(:place)
      event = create(:event, company: company, campaign: campaign, place: place)
      create_list(:document, 3, attachable: event)
      create_list(:document, 2, attachable: campaign)

      get :index, event_id: event.id, format: :json
      expect(response).to be_success

      expect(json.count).to eq(5)
      expect(json.first.keys).to match_array(%w(
        active content_type created_at file_name file_size id name parent
        thumbnail type updated_at url))
      expect(json.map { |d| d['parent'] }.uniq).to match_array %w(campaign event)
    end
  end

  describe "POST 'create'"  do
    let(:event) { create(:event, company: company, campaign: campaign) }

    it 'queue a job for processing the document', :show_in_doc do
      s3object = double
      allow(s3object).to receive(:copy_from).and_return(true)
      allow(s3object).to receive(:exists?).at_least(:once).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        'brandscopic-dev' => double(
          objects: {
            'uploads/dummy/test.jpg' => double(head: double(content_length: 100,
                                                            content_type: 'image/jpeg',
                                                            last_modified: Time.now)),
            'attached_assets/original/test.jpg' => s3object
          }))
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).at_least(:once).and_return('/attached_assets/original/test.jpg')
      expect do
        post 'create', event_id: event.to_param, attached_asset: {
          direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg' },
          format: :json
      end.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      document = AttachedAsset.last
      expect(document.attachable).to eq(event)
      expect(document.asset_type).to eq('document')
      expect(document.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(document.id, 'AttachedAsset')
    end
  end

  describe "GET 'form'", :show_in_doc do
    it 'returns the required information' do
      event = create(:event, company: company, campaign: campaign)
      Sunspot.commit

      get :form, event_id: event.to_param, format: :json
      expect(response).to be_success
      expect(json.keys).to match_array(%w(fields url))
      expect(json['fields'].keys).to match_array(%w(AWSAccessKeyId Secure key policy signature acl success_action_status))
    end
  end

  describe "PUT 'update'", :show_in_doc do
    it 'deactivates the photo' do
      place = create(:place)
      event = create(:event, company: company, campaign: campaign, place: place)
      document = create(:document, attachable: event)

      expect do
        put :update, event_id: event.id, id: document.id,
                     attached_asset: { active: 'false' }, format: :json
        document.reload
      end.to change(document, :active).to(false)
      expect(response).to be_success
    end
  end
end
