require 'rails_helper'

describe DocumentsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:event) { create(:event, company: @company) }
  let(:document) { create(:document, attachable: event) }

  describe "POST 'create'", strategy: :deletion do
    it 'queue a job for processing the photos' do
      s3object = double
      allow(s3object).to receive(:copy_from).and_return(true)
      file_object = double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now))
      objects = double(objects: {
        'uploads/dummy/test.jpg' => file_object,
        'attached_assets/original/test.jpg' => s3object
      })
      allow(file_object).to receive(:exists?).at_least(:once).and_return(true)
      allow(s3object).to receive(:exists?).at_least(:once).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        'brandscopic-dev' => objects)
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).at_least(:once).and_return('/attached_assets/original/test.jpg')
      expect_any_instance_of(AttachedAsset).to receive(:download_url).at_least(:once).and_return('dummy.jpg')
      expect do
        xhr :post, 'create', event_id: event.to_param, attached_asset: { direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg' }, format: :js
      end.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('_document')
      expect(response).to render_template('_attached_asset')
      expect(response).to render_template('create')
      document = AttachedAsset.last
      expect(document.attachable).to eq(event)
      expect(document.asset_type).to eq('document')
      expect(document.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(document.id, 'AttachedAsset')
    end
  end
end
