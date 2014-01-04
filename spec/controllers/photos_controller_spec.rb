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
      AWS::S3.any_instance.should_receive(:buckets).and_return("brandscopic-test" => double(objects: {'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now))}))
      AttachedAsset.any_instance.should_receive(:download_url).and_return('dummy.jpg')
      expect {
        post 'create', event_id: event.to_param, attached_asset: {direct_upload_url: 'https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg'}, format: :js
      }.to change(AttachedAsset, :count).by(1)
      response.should be_success
      response.should render_template('photo')
      response.should render_template('create')
      photo = AttachedAsset.last
      photo.attachable.should == event
      photo.asset_type.should == 'photo'
      photo.direct_upload_url.should == 'https://s3.amazonaws.com/brandscopic-test/uploads/dummy/test.jpg'
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

  describe "GET 'deactivate'" do
    it "deactivates an active photo" do
      photo.update_attribute(:active, true)
      get 'deactivate', event_id: event.to_param, id: photo.to_param, format: :js
      response.should be_success
      photo.reload.active?.should be_false
      response.should render_template('results/photos/_photo_info')
    end
  end

  describe "GET 'activate'" do
    let(:photo){ FactoryGirl.create(:photo, attachable: event, active: false) }

    it "activates an inactive campaign" do
      photo.active?.should be_false
      get 'activate',  event_id: event.to_param, id: photo.to_param, format: :js
      response.should be_success
      photo.reload.active?.should be_true
      response.should render_template('results/photos/_photo_info')
    end
  end

end