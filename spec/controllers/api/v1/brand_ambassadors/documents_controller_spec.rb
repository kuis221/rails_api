require 'rails_helper'

RSpec.describe Api::V1::BrandAmbassadors::DocumentsController, type: :controller do

  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:company_user) { create(:company_user, company: company) }
  let(:user) { company_user.user }
  let(:visit) do
    create(:brand_ambassadors_visit, campaign: campaign,
        company: company, company_user: company_user)
  end

  before { set_api_authentication_headers user, company }

  describe 'GET index' do
    it 'returns http success' do
      xhr :get, 'index', format: :json
      expect(response).to be_success
      expect(response).to render_template('index')
    end

    it "only load the company's documents/folders" do
      company_folder = create(:document_folder, folderable: company, company: company)
      company_document = create(:brand_ambassadors_document, attachable: company)

      create(:document_folder, folderable: visit)
      create(:brand_ambassadors_document, attachable: visit)
      xhr :get, 'index', format: :json
      expect(assigns(:folder_children)).to match_array([company_folder, company_document])
    end

    it "does not load the company's documents/folders that belongs to a subfolder" do
      company_folder = create(:document_folder, folderable: company, company: company)
      company_document = create(:brand_ambassadors_document, attachable: company)

      create(:document_folder, folderable: company, parent_id: 19_999)
      create(:brand_ambassadors_document, attachable: company, folder_id: 19_999)
      xhr :get, 'index', format: :json
      expect(assigns(:folder_children)).to match_array([company_folder, company_document])
    end

    it "only load the company's documents/folders that belongs to the given subfolder" do
      parent = create(:document_folder, folderable: company, company: company)
      create(:brand_ambassadors_document, attachable: company)

      company_folder = create(:document_folder, folderable: company, parent_id: parent.id)
      company_document =  create(:brand_ambassadors_document, attachable: company, folder_id: parent.id)
      xhr :get, 'index', parent_id: parent.id, format: :json
      expect(assigns(:folder_children)).to match_array([company_folder, company_document])
    end

    it "only load the visit's documents/folders" do
      create(:document_folder, folderable: company, company: company)
      create(:brand_ambassadors_document, attachable: company)

      visit_folder   = create(:document_folder, folderable: visit, company: company)
      visit_document = create(:brand_ambassadors_document, attachable: visit)
      xhr :get, 'index', visit_id: visit.id, format: :json
      expect(assigns(:folder_children)).to match_array([visit_folder, visit_document])
    end
  end
end