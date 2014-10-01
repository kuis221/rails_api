require 'rails_helper'

RSpec.describe BrandAmbassadors::DocumentsController, type: :controller do

  let(:company) { create(:company) }
  let(:user) { create(:company_user, company: company) }

  before { sign_in_as_user user }

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end

    it 'returns http success for a visit' do
      ba_visit = create(:brand_ambassadors_visit,
                                    company: company, company_user: user)
      xhr :get, 'new', visit_id: ba_visit.id, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "POST 'create'" do
    describe 'with valid data' do
      before do
        ResqueSpec.reset!
        s3object = double
        allow(s3object).to receive(:copy_from).and_return(true)
        expect_any_instance_of(AWS::S3).to receive(:buckets).at_least(:once).and_return(
          'brandscopic-dev' => double(objects: {
                                        'uploads/dummy/test.jpg' => double(head: double(content_length: 100, content_type: 'image/jpeg', last_modified: Time.now)),
                                        'attached_assets/original/test.jpg' => s3object
                                      }))
        expect_any_instance_of(Paperclip::Attachment).to receive(:path).and_return('/attached_assets/original/test.jpg')
        expect_any_instance_of(AttachedAsset).to receive(:download_url).at_least(:once).and_return('dummy.jpg')
      end

      it 'should successfully create the new record' do
        expect do
          xhr :post, 'create', brand_ambassadors_document: { direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg' }, format: :js
        end.to change(AttachedAsset, :count).by(1)
        expect(response).to be_success
        expect(response).to render_template('documents/create')
        expect(response).to render_template('brand_ambassadors/documents/_document')
        expect(response).to render_template('documents/_document')
        document = AttachedAsset.last
        expect(document.attachable).to eq(company)
        expect(document.asset_type).to eq('ba_document')
        expect(document.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
        expect(document.folder_id).to be_nil
        expect(AssetsUploadWorker).to have_queued(document.id, 'BrandAmbassadors::Document')
      end

      it 'should successfully create the new record inside a folder' do
        expect do
          xhr :post, 'create', brand_ambassadors_document: { direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg' }, folder_id: 2, format: :js
        end.to change(AttachedAsset, :count).by(1)
        expect(response).to be_success
        expect(response).to render_template('documents/create')
        expect(response).to render_template('brand_ambassadors/documents/_document')
        expect(response).to render_template('documents/_document')
        document = AttachedAsset.last
        expect(document.attachable).to eq(company)
        expect(document.asset_type).to eq('ba_document')
        expect(document.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
        expect(document.folder_id).to eql 2
        expect(AssetsUploadWorker).to have_queued(document.id, 'BrandAmbassadors::Document')
      end

      it 'should successfully create the new record for a visit' do
        visit = create(:brand_ambassadors_visit,
                                   company: company, company_user: user)
        expect do
          xhr :post, 'create', visit_id: visit.id, brand_ambassadors_document: { direct_upload_url: 'https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg' }, format: :js
        end.to change(AttachedAsset, :count).by(1)
        expect(response).to be_success
        expect(response).to render_template('documents/create')
        expect(response).to render_template('brand_ambassadors/documents/_document')
        expect(response).to render_template('documents/_document')
        document = AttachedAsset.last
        expect(document.attachable).to eq(visit)
        expect(document.asset_type).to eq('ba_document')
        expect(document.direct_upload_url).to eq('https://s3.amazonaws.com/brandscopic-dev/uploads/dummy/test.jpg')
        expect(document.folder_id).to be_nil
        expect(AssetsUploadWorker).to have_queued(document.id, 'BrandAmbassadors::Document')
      end
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(BrandAmbassadors::Document, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:document).errors.count > 0
    end
  end

  describe 'PATCH update' do
    let(:document) { create(:brand_ambassadors_document, attachable: company) }
    it 'should update the document' do
      document
      expect do
        xhr :patch, 'update', id: document.to_param, brand_ambassadors_document: { folder_id: 99 }, format: :js
      end.not_to change(BrandAmbassadors::Document, :count)
      expect(document.reload.folder_id).to eql 99
      expect(response).to render_template('update')
    end
  end

  describe 'GET move' do
    let(:document) { create(:brand_ambassadors_document, attachable: company) }
    it 'should update the document' do
      xhr :get, 'move', id: document.to_param, format: :js
      expect(response).to render_template('move')
    end
  end

end
