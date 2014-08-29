require 'rails_helper'

RSpec.describe BrandAmbassadors::DocumentsController, :type => :controller do

  let(:company){ FactoryGirl.create(:company) }
  let(:user){ FactoryGirl.create(:company_user, company: company) }

  before{ sign_in_as_user user }

  describe "GET 'new'" do
    it "returns http success" do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end

    it "returns http success" do
      ba_visit = FactoryGirl.create(:brand_ambassadors_visit,
        company: company, company_user: user)
      xhr :get, 'new', visit_id: ba_visit.id, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "POST 'create'" do
    it "should successfully create the new record" do
      ResqueSpec.reset!
      s3object = double()
      allow(s3object).to receive(:copy_from).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        "brandscopic-dev" => double(objects: {
          'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now)),
          'attached_assets/original/test.jpg' => s3object
        } ))
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).and_return('/attached_assets/original/test.jpg')
      expect_any_instance_of(AttachedAsset).to receive(:download_url).and_return('dummy.jpg')
      expect {
        xhr :post, 'create', attached_asset: {direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg'}, format: :js
      }.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('documents/create')
      expect(response).to render_template('brand_ambassadors/documents/_document')
      expect(response).to render_template('documents/_document')
      document = AttachedAsset.last
      expect(document.attachable).to eq(company)
      expect(document.asset_type).to eq('ba_document')
      expect(document.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(document.id)
    end

    it "should successfully create the new record for a visit" do
      ResqueSpec.reset!
      s3object = double()
      allow(s3object).to receive(:copy_from).and_return(true)
      expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
        "brandscopic-dev" => double(objects: {
          'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now)),
          'attached_assets/original/test.jpg' => s3object
        } ))
      expect_any_instance_of(Paperclip::Attachment).to receive(:path).and_return('/attached_assets/original/test.jpg')
      expect_any_instance_of(AttachedAsset).to receive(:download_url).and_return('dummy.jpg')

      visit = FactoryGirl.create(:brand_ambassadors_visit,
        company: company, company_user: user)
      expect {
        xhr :post, 'create', visit_id: visit.id, attached_asset: {direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg'}, format: :js
      }.to change(AttachedAsset, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('documents/create')
      expect(response).to render_template('brand_ambassadors/documents/_document')
      expect(response).to render_template('documents/_document')
      document = AttachedAsset.last
      expect(document.attachable).to eq(visit)
      expect(document.asset_type).to eq('ba_document')
      expect(document.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
      expect(AssetsUploadWorker).to have_queued(document.id)
    end

    it "should render the form_dialog template if errors" do
      expect {
        xhr :post, 'create', format: :js
      }.not_to change(BrandAmbassadors::Visit, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:document).errors.count > 0
    end
  end

end
