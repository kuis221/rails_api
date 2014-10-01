require 'rails_helper'

describe PhotosController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:event) { create(:event, campaign: create(:campaign, company: @company)) }
  let(:photo) { create(:photo, attachable: event) }

  describe "POST 'create'", strategy: :deletion do
    it 'queue a job for processing the photos' do
      ResqueSpec.reset!
      s3object = double
      allow(s3object).to receive(:copy_from).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        'brandscopic-dev' => double(objects: {
                                      'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now)),
                                      'attached_assets/original/test.jpg' => s3object
                                    }))
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).and_return('/attached_assets/original/test.jpg')
      expect_any_instance_of(AttachedAsset).to receive(:download_url).and_return('dummy.jpg')
      expect do
        xhr :post, 'create', event_id: event.to_param, attached_asset: { direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg' }, format: :js
      end.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('_photo')
      expect(response).to render_template('create')
      photo = AttachedAsset.last
      expect(photo.attachable).to eq(event)
      expect(photo.asset_type).to eq('photo')
      expect(photo.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(photo.id, 'AttachedAsset')
    end
  end

  describe "GET 'new'" do
    it 'should render the comment form for a event comment' do
      xhr :get, 'new', event_id: event.to_param, format: :js
      expect(response).to render_template('photos/_form')
      expect(response).to render_template('_form_dialog')
      expect(assigns(:photo).new_record?).to be_truthy
      expect(assigns(:photo).attachable).to eq(event)
    end
  end

  describe "GET 'processing_status'" do
    it 'should return the photos status' do
      xhr :get, 'processing_status', event_id: event.to_param, photos: [photo.id], format: :js
      expect(response).to be_success
      expect(response).to render_template('processing_status')
    end
  end

  describe "GET 'deactivate'" do
    it 'deactivates an active photo' do
      photo.update_attribute(:active, true)
      xhr :get, 'deactivate', event_id: event.to_param, id: photo.to_param, format: :js
      expect(response).to be_success
      expect(photo.reload.active?).to be_falsey
    end
  end

  describe "GET 'activate'" do
    let(:photo) { create(:photo, attachable: event, active: false) }

    it 'activates an inactive campaign' do
      expect(photo.active?).to be_falsey
      xhr :get, 'activate',  event_id: event.to_param, id: photo.to_param, format: :js
      expect(response).to be_success
      expect(photo.reload.active?).to be_truthy
    end
  end

end
