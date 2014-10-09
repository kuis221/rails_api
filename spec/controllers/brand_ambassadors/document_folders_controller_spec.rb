require 'rails_helper'

RSpec.describe BrandAmbassadors::DocumentFoldersController, type: :controller do

  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:company_user, company: company) }
  let(:visit) do
    create(:brand_ambassadors_visit, campaign: campaign,
        company: company, company_user: user)
  end

  before { sign_in_as_user user }

  describe 'GET index' do
    it 'returns http success' do
      xhr :get, 'index', format: :js
      expect(response).to be_success
      expect(response).to render_template('index')
    end

    it "only load the company's documents/folders" do
      company_folder = create(:document_folder, folderable: company)
      company_document = create(:brand_ambassadors_document, attachable: company)

      create(:document_folder, folderable: visit)
      create(:brand_ambassadors_document, attachable: visit)
      xhr :get, 'index', format: :js
      expect(assigns(:folder_children)).to match_array([company_folder, company_document])
    end

    it "does not load the company's documents/folders that belongs to a subfolder" do
      company_folder = create(:document_folder, folderable: company)
      company_document = create(:brand_ambassadors_document, attachable: company)

      create(:document_folder, folderable: visit, folderable: company, parent_id: 19_999)
      create(:brand_ambassadors_document, attachable: visit, attachable: company, folder_id: 19_999)
      xhr :get, 'index', format: :js
      expect(assigns(:folder_children)).to match_array([company_folder, company_document])
    end

    it "only load the company's documents/folders that belongs to the given subfolder" do
      parent = create(:document_folder, folderable: company)
      create(:brand_ambassadors_document, attachable: company)

      company_folder = create(:document_folder, folderable: visit, folderable: company, parent_id: parent.id)
      company_document =  create(:brand_ambassadors_document, attachable: visit, attachable: company, folder_id: parent.id)
      xhr :get, 'index', parent_id: parent.id, format: :js
      expect(assigns(:folder_children)).to match_array([company_folder, company_document])
    end

    it "only load the visit's documents/folders" do
      create(:document_folder, folderable: company)
      create(:brand_ambassadors_document, attachable: company)

      visit_folder   = create(:document_folder, folderable: visit)
      visit_document = create(:brand_ambassadors_document, attachable: visit)
      xhr :get, 'index', visit_id: visit.id, format: :js
      expect(assigns(:folder_children)).to match_array([visit_folder, visit_document])
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end

    it 'returns http success' do
      visit = create(:brand_ambassadors_visit, campaign: campaign,
        company: company, company_user: user)
      xhr :get, 'new', visit_id: visit.id, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "POST 'create'" do
    it 'should successfully create the new record' do
      expect do
        xhr :post, 'create', document_folder: { name: 'folder name' }, format: :js
      end.to change(DocumentFolder, :count).by(1)
      expect(response).to render_template('create')
      expect(response).to render_template('_document_folder')
      folder = DocumentFolder.last
      expect(folder.folderable).to eql company
      expect(folder.company_id).to eql company.id
    end

    it 'should successfully create the new record for a visit' do
      expect do
        xhr :post, 'create', visit_id: visit.id, document_folder: { name: 'folder name' }, format: :js
      end.to change(DocumentFolder, :count).by(1)
      expect(response).to render_template('create')
      expect(response).to render_template('_document_folder')
      folder = DocumentFolder.last
      expect(folder.folderable).to eql visit
      expect(folder.company_id).to eql company.id
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(DocumentFolder, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:document_folder).errors.count > 0
    end
  end

end
