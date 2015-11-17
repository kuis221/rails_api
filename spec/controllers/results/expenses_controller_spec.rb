require 'rails_helper'

describe Results::ExpensesController, type: :controller do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company, role_id: create(:role, company: company).id) }
  let(:company_user) { user.company_users.first }
  let(:brand) { create(:brand, name: 'Brand 1', company: company) }
  let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }

  before { sign_in_as_user company_user }

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it 'should return http success' do
      get 'items'
      expect(response).to be_success
      expect(response).to render_template('results/expenses/items')
      expect(response).to render_template('results/expenses/_totals')
    end
  end

  describe "GET 'list_export'", :search, :inline_jobs do
    let!(:created_at) { DateTime.parse('2014-07-02 10:00 -07:00') }
    let!(:updated_at) { DateTime.parse('2015-07-01 10:00 -07:00') }
    let!(:approved_at) { DateTime.parse('2015-07-02 10:00 -07:00') }
    let!(:submitted_at) { DateTime.parse('2015-07-01 10:00 -07:00') }

    before do
      Kpi.create_global_kpis
    end

    it 'should return an empty xls with the correct headers' do
      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'EVENT START DATE', 'EVENT END DATE',
         'CREATED AT', 'CREATED BY', 'LAST MODIFIED', 'MODIFIED BY', 'SPENT']
      ])
    end

    it 'should return an empty xls with the correct headers' do
      create(:approved_event, campaign: campaign,
              start_date: '08/21/2013', end_date: '08/21/2013',
              start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'),
              submitted_at: submitted_at, approved_at: approved_at,
              event_expenses: [
                build(:event_expense, category: 'Entertainment', amount: 10, created_at: created_at, updated_at: updated_at)])

      create(:approved_event, campaign: campaign,
              start_date: '08/20/2013', end_date: '08/20/2013',
              start_time: '9:00am', end_time: '10:00am', place: create(:place, name: 'Place 2'),
              event_expenses: [
                build(:event_expense, category: 'Uncategorized', amount: 20, created_at: created_at, updated_at: updated_at)])

      Sunspot.commit
      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      export = ListExport.last

      expect(export.reload).to have_rows([
        ['CAMPAIGN NAME', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'EVENT START DATE', 'EVENT END DATE',
         'CREATED AT', 'CREATED BY', 'LAST MODIFIED', 'MODIFIED BY', 'SPENT', 'ENTERTAINMENT', 'UNCATEGORIZED'],
        ['Test Campaign FY01', 'Place 2', 'Place 2, 11 Main St., New York City, NY, 12345', 'US',
         '2013-08-20 09:00', '2013-08-20 10:00', '2014-07-02 10:00', 'Test User', '2015-07-01 10:00', 'Test User', '20.0', nil, '20.0'],
        ['Test Campaign FY01', 'Place 1', 'Place 1, 11 Main St., New York City, NY, 12345', 'US',
         '2013-08-21 20:00', '2013-08-21 23:00', '2014-07-02 10:00', 'Test User', '2015-07-01 10:00', 'Test User', '10.0', '10.0', nil]
      ])
    end

    it 'should return an zip file' do
      create(:approved_event, campaign: campaign,
              start_date: '08/21/2013', end_date: '08/21/2013',
              start_time: '8:00pm', end_time: '11:00pm', place: create(:place, name: 'Place 1'),
              submitted_at: submitted_at, approved_at: approved_at,
              event_expenses: [
                build(:event_expense, category: 'Entertainment', amount: 10, created_at: created_at, updated_at: updated_at)])

      create(:approved_event, campaign: campaign,
              start_date: '08/20/2013', end_date: '08/20/2013',
              start_time: '9:00am', end_time: '10:00am', place: create(:place, name: 'Place 2'),
              event_expenses: [
                build(:event_expense, category: 'Uncategorized', amount: 20, created_at: created_at, updated_at: updated_at)])

      Sunspot.commit
      expect { xhr :get, 'index', format: :zip }.to change(ListExport, :count).by(1)
      export = ListExport.last

      expect(export.file_content_type).to eq('application/octet-stream')
      expect(export.export_format).to eq('zip')
    end
  end

  describe "GET 'index'" do
    it 'queue the job for export the list' do
      expect(ListExportWorker).to receive(:perform_async).with(kind_of(Numeric))
      expect do
        xhr :get, :index, format: :xls
      end.to change(ListExport, :count).by(1)
    end
  end
end
