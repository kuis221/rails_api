require 'spec_helper'

describe DocumentsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:event) {FactoryGirl.create(:event, company: @company)}
  let(:document) {FactoryGirl.create(:document, attachable: event)}

  describe "POST 'create'", strategy: :deletion do
    it "queue a job for processing the photos" do
      ResqueSpec.reset!
      AWS::S3.any_instance.should_receive(:buckets).and_return("brandscopic-test" => double(objects: {'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now))}))
      AttachedAsset.any_instance.should_receive(:download_url).and_return('dummy.jpg')
      expect {
        post 'create', event_id: event.to_param, attached_asset: {direct_upload_url: 'https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg'}, format: :js
      }.to change(AttachedAsset, :count).by(1)
      response.should be_success
      response.should render_template('document')
      response.should render_template('create')
      document = AttachedAsset.last
      document.attachable.should == event
      document.asset_type.should == 'document'
      document.direct_upload_url.should == 'https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg'
      AssetsUploadWorker.should have_queued(document.id)
    end
  end


  describe "GET 'new'" do
    it "should render the comment form for a event comment" do
      get 'new', event_id: event.to_param, format: :js
      response.should render_template('documents/_form')
      response.should render_template(:form_dialog)
      assigns(:document).new_record?.should be_true
      assigns(:document).attachable.should == event
    end
  end

end