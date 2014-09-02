require 'rails_helper'

RSpec.describe BrandAmbassadors::DocumentFoldersController , type: :controller do

  let(:company){ FactoryGirl.create(:company) }
  let(:user){ FactoryGirl.create(:company_user, company: company) }
  let(:visit) { FactoryGirl.create(:brand_ambassadors_visit,
        company: company, company_user: user) }

  before{ sign_in_as_user user }

  describe "GET 'new'" do
    it "returns http success" do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end

    it "returns http success" do
      visit = FactoryGirl.create(:brand_ambassadors_visit,
        company: company, company_user: user)
      xhr :get, 'new', visit_id: visit.id, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "POST 'create'" do
    it "should successfully create the new record" do
      expect {
        xhr :post, 'create', document_folder: {name: 'folder name'}, format: :js
      }.to change(DocumentFolder, :count).by(1)
      expect(response).to render_template('create')
      expect(response).to render_template('_document_folder')
      folder = DocumentFolder.last
      expect(folder.folderable).to eql company
      expect(folder.company_id).to eql company.id
    end

    it "should successfully create the new record for a visit" do
      expect {
        xhr :post, 'create', visit_id: visit.id, document_folder: {name: 'folder name'}, format: :js
      }.to change(DocumentFolder, :count).by(1)
      expect(response).to render_template('create')
      expect(response).to render_template('_document_folder')
      folder = DocumentFolder.last
      expect(folder.folderable).to eql visit
      expect(folder.company_id).to eql company.id
    end

    it "should render the form_dialog template if errors" do
      expect {
        xhr :post, 'create', format: :js
      }.not_to change(DocumentFolder, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:document_folder).errors.count > 0
    end
  end

end
