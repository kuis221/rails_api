require 'spec_helper'

describe PhotosController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  let(:event) {FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign))}
  let(:photo) {FactoryGirl.create(:photo, attachable: event)}

  describe "POST 'create'" do
    it "queue a job for processing the photos" do
      ResqueSpec.reset!
      AWS::S3.any_instance.should_receive(:buckets).and_return("brandscopic-dev" => double(objects: {'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now))}))
      AttachedAsset.any_instance.should_receive(:download_url).and_return('dummy.jpg')
      expect {
        post 'create', event_id: event.to_param, attached_asset: {direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg'}, format: :js
      }.to change(AttachedAsset, :count).by(1)
      response.should be_success
      response.should render_template('photo')
      response.should render_template('create')
      photo = AttachedAsset.last
      photo.attachable.should == event
      photo.asset_type.should == 'photo'
      photo.direct_upload_url.should == 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg'
      AssetsUploadWorker.should have_queued(photo.id)
    end
  end


  describe "GET 'new'" do
    it "should render the comment form for a event comment" do
      get 'new', event_id: event.to_param, format: :js
      response.should render_template('photos/_form')
      response.should render_template(:form_dialog)
      assigns(:photo).new_record?.should be_true
      assigns(:photo).attachable.should == event
    end
  end

  describe "GET 'processing_status'" do
    it "should return the photos status" do
      get 'processing_status', event_id: event.to_param, photos: [photo.id], format: :js
      response.should be_success
      response.should render_template('processing_status')
    end
  end

end