require 'rails_helper'

RSpec.describe BrandAmbassadors::VisitsController, :type => :controller do

  let(:company){ FactoryGirl.create(:company) }
  let(:campaign){ FactoryGirl.create(:campaign, name: 'Imperial FY14', company: company) }
  let(:user){ FactoryGirl.create(:company_user, company: company) }

  before{ sign_in_as_user user }
  before{ ResqueSpec.reset! }

  describe "GET 'index'" do
    it "returns http success", search: true do
      get 'index', format: :json
      expect(response).to be_success
    end

    it "queue the job for export the list" do
      expect{
        xhr :get, :index, format: :xls
      }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('BrandAmbassadors::VisitsController')
      expect(export.export_format).to eql('xls')
    end

    it "queue the job for export the list" do
      expect{
        xhr :get, :index, format: :pdf
      }.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('BrandAmbassadors::VisitsController')
      expect(export.export_format).to eql('pdf')
    end
  end


  describe "GET 'list_export'", search: true do
    it "should return an empty book with the correct headers" do
      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows.count).to eql 1
        expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to eql [
          "START DATE", "END DATE", "EMPLOYEE", "AREA", "CITY", "CAMPAIGN", "TYPE"
        ]
      end
    end

    it "should include the event results" do
      visit_user = FactoryGirl.create(:company_user,
        user: FactoryGirl.create(:user, first_name: 'Michale', last_name: 'Jackson'),
        company: company, role: user.role)

      brand = FactoryGirl.create(:brand, name: 'Imperial', company_id: company.to_param)

      area = FactoryGirl.create(:area, name: 'Area 1', company_id: company.to_param)

      visit = FactoryGirl.create(:brand_ambassadors_visit,
        visit_type: 'pto', description: 'Test Visit description', company_user: visit_user,
        start_date: '01/23/2014', end_date: '01/24/2014', campaign: campaign, area: area,
        city: 'Test City', company: company)
      Sunspot.commit

      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      expect(ListExportWorker).to have_queued(ListExport.last.id)
      ResqueSpec.perform_all(:export)
      spreadsheet_from_last_export do |doc|
        rows = doc.elements.to_a('//Row')
        expect(rows.count).to eql 2
        expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to eql [
          "2014-01-23", "2014-01-24", "Michale Jackson", "Area 1", "Test City", "Imperial FY14", "PTO"
        ]
      end
    end
  end

  describe "GET 'edit'" do
    let(:visit){ FactoryGirl.create(:brand_ambassadors_visit, campaign: campaign, company: company) }
    it "returns http success" do
      xhr :get, 'edit', id: visit.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "POST 'create'" do
    it "should successfully create the new record" do
      expect {
        xhr :post, 'create', brand_ambassadors_visit: {
            visit_type: 'pto', description: 'Test Visit description',
            company_user_id: user.id, start_date: '01/23/2014', end_date: '01/24/2014',
            campaign_id: campaign.id, area_id: 20, city: 'Test City'
        }, format: :js
      }.to change(BrandAmbassadors::Visit, :count).by(1)
      visit = BrandAmbassadors::Visit.last
      expect(visit.visit_type).to eq('pto')
      expect(visit.description).to eq('Test Visit description')
      expect(visit.company_user_id).to eq(user.id)
      expect(visit.company_id).to eq(company.id)
      expect(visit.campaign_id).to eq(campaign.id)
      expect(visit.area_id).to eq(20)
      expect(visit.active).to eq(true)

      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it "should render the form_dialog template if errors" do
      expect {
        xhr :post, 'create', format: :js
      }.not_to change(BrandAmbassadors::Visit, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:visit).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:visit){ FactoryGirl.create(:brand_ambassadors_visit, campaign: campaign, company: company) }

    it "deactivates an active visit" do
      visit.update_attribute(:active, true)
      xhr :get, 'deactivate', id: visit.to_param, format: :js
      expect(response).to be_success
      expect(visit.reload.active?).to be_falsey
    end
  end

  describe "GET 'activate'" do
    let(:visit){ FactoryGirl.create(:brand_ambassadors_visit, campaign: campaign, company: company, active: false) }

    it "activates an inactive `visit" do
      expect(visit.active?).to be_falsey
      xhr :get, 'activate', id: visit.to_param, format: :js
      expect(response).to be_success
      expect(visit.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    let(:visit){ FactoryGirl.create(:brand_ambassadors_visit, campaign: campaign, company: company) }
    let(:another_user){ FactoryGirl.create(:company_user, company: company) }

    it "must update the visit attributes" do
      new_campaign = FactoryGirl.create(:campaign, company: company)
      xhr :put, 'update', id: visit.to_param, brand_ambassadors_visit: {
        visit_type: 'pto', description: 'New Visit description',
        company_user_id: another_user.id, start_date: '01/23/2014', end_date: '01/24/2014',
        campaign_id: new_campaign.id, area_id: 25, city: 'New Test City'}, format: :js
      expect(assigns(:visit)).to eq(visit)
      expect(response).to be_success
      visit.reload
      expect(visit.visit_type).to eq('pto')
      expect(visit.description).to eq('New Visit description')
      expect(visit.company_user_id).to eq(another_user.id)
      expect(visit.start_date).to eql Date.new(2014, 01, 23)
      expect(visit.end_date).to eql Date.new(2014, 01, 24)
      expect(visit.campaign_id).to eq(new_campaign.id)
      expect(visit.area_id).to eq(25)
    end
  end

end
