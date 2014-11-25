require 'rails_helper'

describe Results::EventStatusController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company_user) { user.current_company_user }
  let(:company) { user.companies.first }
  let(:campaign) { create(:campaign, company: company, name: 'Test Campaign FY01') }

  before { user }

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end

    describe 'XLS export' do
      it 'queue the job for export the list' do
        expect do
          xhr :get, :index, format: :xls
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
      end
    end

    describe 'PDF export' do
      let(:kpi) { Kpi.events }
      before { Kpi.create_global_kpis }
      before { ResqueSpec.reset! }

      it 'queue the job for export the list' do
        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'campaign' }, format: :pdf
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
      end

      it 'should render the PDF even if no data' do
        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'campaign' }, format: :pdf
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        reader = PDF::Reader.new(open(export.reload.file.url))
        expect(reader.page_count).to eql 1
        reader.pages.each do |page|
          expect(page.text).to be_empty
        end
      end

      it 'should render the report for the campaign as PDF' do
        create(:approved_event, company: company, campaign: campaign)
        create(:submitted_event, company: company, campaign: campaign)

        create(:goal, goalable: campaign, kpi: kpi, value: 30)

        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'campaign' }, format: :pdf
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        reader = PDF::Reader.new(open(export.reload.file.url))
        reader.pages.each do |page|
          # PDF to text seems to not always return the same results
          # with white spaces, so, remove them and look for strings
          # without whitespaces
          text = page.text.gsub(/[\s\n]/, '')
          expect(text).to include 'TestCampaignFY01'
          expect(text).to include '30GOAL'
          expect(text).to include 'EVENTS28REMAINING11'
        end
      end

      it 'should render the report for the campaign grouped by Place as PDF' do
        area = create(:area, name: 'Area 1', company: company)
        place = create(:place, name: 'Place 1')
        area.places << place
        campaign.areas << area

        create(:approved_event, company: company, campaign: campaign, place: place)
        create(:submitted_event, company: company, campaign: campaign, place: place)

        create(:goal, parent: campaign, goalable: area, kpi: kpi, value: 10)

        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'place' }, format: :pdf
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        reader = PDF::Reader.new(open(export.reload.file.url))
        reader.pages.each do |page|
          # PDF to text seems to not always return the same results
          # with white spaces, so, remove them and look for strings
          # without whitespaces
          text = page.text.gsub(/[\s\n]/, '')
          expect(text).to include 'TestCampaignFY01'
          expect(text).to include 'Area1'
          expect(text).to include '10GOAL'
          expect(text).to include '8EVENTSREMAINING11'
        end
      end

      it 'should render the report for the campaign grouped by Staff as PDF' do
        company_user.campaigns << campaign

        create(:approved_event, company: company, campaign: campaign, user_ids: [company_user.id])
        create(:submitted_event, company: company, campaign: campaign, user_ids: [company_user.id])

        create(:goal, parent: campaign, goalable: company_user, kpi: kpi, value: 50)

        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'staff' }, format: :pdf
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        reader = PDF::Reader.new(open(export.reload.file.url))
        reader.pages.each do |page|
          # PDF to text seems to not always return the same results
          # with white spaces, so, remove them and look for strings
          # without whitespaces
          text = page.text.gsub(/[\s\n]/, '')
          expect(text).to include 'TestCampaignFY01'
          expect(text).to include 'TestUser'
          expect(text).to include '50GOAL'
          expect(text).to include '48EVENTSREMAINING11'
        end
      end
    end
  end

  describe "POST 'report'" do
    it 'should call the promo_hours_graph_data method to get the overall data for the campaign' do
      expect(Campaign).to receive(:promo_hours_graph_data).and_return([])
      xhr :post, 'report', report: { campaign_id: campaign.id }, format: :js
      expect(response).to be_success
      expect(response).to render_template('results/event_status/report')
      expect(response).to render_template('results/event_status/_report')
    end

    it 'should call the event_status_data_by_areas method to get the overall data for the campaign' do
      expect_any_instance_of(Campaign).to receive(:event_status_data_by_areas).with(company_user).and_return([])
      xhr :post, 'report', report: { campaign_id: campaign.id, group_by: 'place' }, format: :js
      expect(response).to be_success
      expect(response).to render_template('results/event_status/report')
      expect(response).to render_template('results/event_status/_report')
    end

    it 'should call the event_status_data_by_areas method to get the overall data for the campaign' do
      expect_any_instance_of(Campaign).to receive(:event_status_data_by_staff).and_return([])
      xhr :post, 'report', report: { campaign_id: campaign.id, group_by: 'staff' }, format: :js
      expect(response).to be_success
      expect(response).to render_template('results/event_status/report')
      expect(response).to render_template('results/event_status/_report')
    end
  end

  describe "POST 'index'" do
    it 'should return http success' do
      Sunspot.commit
      post 'index', 'report' => { 'campaign_id' => campaign.id }
      expect(response).to be_success
    end
  end
end
