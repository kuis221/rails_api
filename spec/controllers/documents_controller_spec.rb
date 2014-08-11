require 'spec_helper'

describe DocumentsController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:event) {FactoryGirl.create(:event, company: @company)}
  let(:document) {FactoryGirl.create(:document, attachable: event)}

  describe "POST 'create'", strategy: :deletion do
    it "queue a job for processing the photos" do
      ResqueSpec.reset!
      s3object = double()
      allow(s3object).to receive(:copy_from).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        "brandscopic-test" => double(objects: {
          'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now)),
          'attached_assets/original/test.jpg' => s3object
        } ))
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).at_least(:once).and_return('/attached_assets/original/test.jpg')
      expect_any_instance_of(AttachedAsset).to receive(:download_url).and_return('dummy.jpg')
      expect {
        post 'create', event_id: event.to_param, attached_asset: {direct_upload_url: 'https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg'}, format: :js
      }.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('document')
      expect(response).to render_template('create')
      document = AttachedAsset.last
      expect(document.attachable).to eq(event)
      expect(document.asset_type).to eq('document')
      expect(document.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(document.id)
    end
  end


  describe "GET 'new'" do
    it "should render the comment form for a event comment" do
      get 'new', event_id: event.to_param, format: :js
      expect(response).to render_template('documents/_form')
      expect(response).to render_template(:form_dialog)
      expect(assigns(:document).new_record?).to be_truthy
      expect(assigns(:document).attachable).to eq(event)
    end
  end

end