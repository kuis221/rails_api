require 'rails_helper'

RSpec.describe Results::DataExtractsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  let(:data_extract) { create(:data_extract_event_data) }

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_select_data_source')
    end
    it 'Not select data source' do
      xhr :get, 'new', step: 2, data_extract: { source: '' }, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_configure')
    end
    it 'select data source' do
      xhr :get, 'new', step: 2, data_extract: { source: 'event' }, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form_configure')
    end

    it 'queues the job for export the report' do
      expect(ListExportWorker).to receive(:perform_async).with(kind_of(Numeric))
      expect do
        xhr :get, :new, data_extract: { source: 'event_data' }, format: :csv
      end.to change(ListExport, :count).by(1)
    end
  end

  describe "GET 'show'" do
    it 'returns http success' do
      xhr :get, 'show', id: data_extract.id
      expect(response).to be_success
      expect(response).to render_template('show')
    end

    it 'queues the job for export the report' do
      expect(ListExportWorker).to receive(:perform_async).with(kind_of(Numeric))
      expect do
        xhr :get, :show, id: data_extract.id, format: :csv
      end.to change(ListExport, :count).by(1)
    end
  end

  describe "GET 'list_export'", :search, :inline_jobs do
    before do
      Kpi.create_global_kpis
    end

    let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }

    it 'should return an empty csv with the correct headers' do
      data_extract.update_attributes(columns: %w(campaign_name end_date end_time))
      expect { xhr :get, 'show', id: data_extract.id, format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last

      expect(export.reload).to have_rows([
        ['Campaign', 'End Date', 'End Time']
      ])
    end
  end

  describe "GET 'deactivate'" do
    it 'deactivates an active data extract report' do
      data_extract.update_attribute(:active, true)
      xhr :get, 'deactivate', id: data_extract.to_param, format: :js
      expect(response).to be_success
      expect(data_extract.reload.active?).to be_falsey
    end

    it 'activates an inactive report' do
      data_extract.update_attribute(:active, false)
      xhr :get, 'activate', id: data_extract.to_param, format: :js
      expect(response).to be_success
      expect(data_extract.reload.active?).to be_truthy
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      xhr :post, 'create', format: :js
      expect(response).to be_success
    end

    it 'should succeed' do
      expect do
        xhr :post, 'create', data_extract: {
          name: 'Test data extract report',
          description: 'Test data extract report description',
          source: 'activity',
          params: { activity_type_id: 1 } },
          step: 4, format: :js
      end.to change(DataExtract, :count).by(1)
      expect(response).to redirect_to results_reports_path

      report = DataExtract.last
      expect(report.name).to eql 'Test data extract report'
      expect(report.params).to eql('activity_type_id' => 1, 'campaign_id' => nil)
      expect(report.description).to eql 'Test data extract report description'
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.to_not change(DataExtract, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      expect(assigns(:data_extract).errors.count).to be > 0
    end
  end

  describe "PUT 'update'" do
    it 'must update the report attributes' do
      put 'update', id: data_extract.to_param, data_extract: { name: 'Test Report', description: 'Test Report description' }
      expect(assigns(:data_extract)).to eq(data_extract)
      expect(response).to redirect_to(results_reports_path)
      data_extract.reload
      expect(data_extract.name).to eq('Test Report')
      expect(data_extract.description).to eq('Test Report description')
    end
  end
end
