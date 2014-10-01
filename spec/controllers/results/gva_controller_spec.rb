require 'rails_helper'
require 'open-uri'

describe Results::GvaController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it 'should return http success' do
      get 'index'
      expect(response).to be_success
    end

    describe 'XLS export' do
      before { ResqueSpec.reset! }
      it 'queue the job for export the list' do
        expect do
          xhr :get, :index, format: :xls
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
      end
    end

    describe 'PDF export' do
      let(:campaign) { create(:campaign, name: 'My Super campaign', company: @company) }
      let(:kpi) { create(:kpi, name: 'My Custom KPI', company: @company) }
      before { ResqueSpec.reset! }
      before { campaign.add_kpi kpi }

      it 'queue the job for export the list' do
        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'campaign', view_mode: 'graph' }, format: :pdf
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
      end

      it 'should render the PDF even if no data' do
        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'campaign', view_mode: 'graph' }, format: :pdf
        end.to change(ListExport, :count).by(1)
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)

        reader = PDF::Reader.new(open(export.reload.file.url))
        reader.pages.each do |page|
          expect(page.text).to include 'Goals vs. Actual'
        end
      end

      it 'should render the report for the campaign' do
        event = create(:approved_event, company: @company, campaign: campaign)
        event.result_for_kpi(kpi).value = '25'
        event.save

        event = create(:submitted_event, company: @company, campaign: campaign)
        event.result_for_kpi(kpi).value = '20'
        event.save

        create(:goal, goalable: campaign, kpi: kpi, value: '100')

        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'campaign', view_mode: 'graph' }, format: :pdf
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
          expect(text).to include 'MySupercampaign'
          expect(text).to include 'Goalsvs.Actual'
          expect(text).to include 'MyCustomKPI'
          expect(text).to include '45%'
          expect(text).to include '45OF100GOAL'
        end
      end

      it 'should render the report for the campaign' do
        event = create(:approved_event, company: @company, campaign: campaign)
        event.result_for_kpi(kpi).value = '25'
        event.save

        event = create(:submitted_event, company: @company, campaign: campaign)
        event.result_for_kpi(kpi).value = '20'
        event.save

        create(:goal, goalable: campaign, kpi: kpi, value: '100')

        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'campaign', view_mode: 'graph' }, format: :pdf
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
          expect(text).to include 'MySupercampaign'
          expect(text).to include 'Goalsvs.Actual'
          expect(text).to include 'MyCustomKPI'
          expect(text).to include '45%'
          expect(text).to include '45OF100GOAL'
        end
      end

      it 'should render the report for the campaign' do
        campaign.add_kpi kpi
        @company_user.campaigns << campaign

        create(:goal, parent: campaign, goalable: @company_user, kpi: kpi, value: 50)

        event = create(:approved_event, company: @company, campaign: campaign, user_ids: [@company_user.id])
        event.result_for_kpi(kpi).value = '25'
        event.save

        event = create(:submitted_event, company: @company, campaign: campaign, user_ids: [@company_user.id])
        event.result_for_kpi(kpi).value = '20'
        event.save

        create(:goal, goalable: campaign, kpi: kpi, value: '100')

        expect do
          xhr :get, :index, report: { campaign_id: campaign.id, group_by: 'staff', view_mode: 'graph' }, format: :pdf
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
          expect(text).to include 'MySupercampaign'
          expect(text).to include 'Goalsvs.Actual'
          expect(text).to include 'MyCustomKPI'
          expect(text).to include '90%'
          expect(text).to include '45OF50GOAL'
        end
      end
    end
  end

  describe "POST 'report'" do
    let(:campaign) { create(:campaign, company: @company) }
    it 'should return http success' do
      xhr :post, 'report', report: { campaign_id: campaign.id }, format: :js
      expect(response).to be_success
      expect(response).to render_template('results/gva/report')
      expect(response).to render_template('results/gva/_report')
    end

    it 'should include any goals for the campaign' do
      kpi = create(:kpi, company: campaign.company)
      events = create_list(:event, 3, campaign: campaign)
      create_list(:event, 2, campaign: create(:campaign, company: campaign.company))

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save
      xhr :post, 'report', report: { campaign_id: campaign.id }, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [goal]
    end

    it 'should include only goals for the given user' do
      kpi = create(:kpi, company: campaign.company)
      events = create_list(:event, 3, campaign: campaign)
      create_list(:event, 2, campaign: create(:campaign, company: campaign.company))

      user = create(:company_user, company: campaign.company)

      events.each { |e| e.users << user }

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save

      user_goal = user.goals.for_kpi(kpi)
      user_goal.parent = campaign
      user_goal.value = 100
      user_goal.save

      xhr :post, 'report', report: { campaign_id: campaign.id }, item_type: 'CompanyUser', item_id: user.id, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [user_goal]
    end

    it 'should include only goals for the given team' do
      kpi = create(:kpi, company: campaign.company)
      events = create_list(:event, 3, campaign: campaign)
      create_list(:event, 2, campaign: create(:campaign, company: campaign.company))

      team = create(:team, company: campaign.company)

      events.each { |e| e.teams << team }

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save

      team_goal = team.goals.for_kpi(kpi)
      team_goal.parent = campaign
      team_goal.value = 100
      team_goal.save

      xhr :post, 'report', report: { campaign_id: campaign.id }, item_type: 'Team', item_id: team.id, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [team_goal]
    end

    it 'should include only goals for the given area' do
      kpi = create(:kpi, company: campaign.company)
      place = create(:place)
      events = create_list(:event, 3, campaign: campaign, place: place)
      create_list(:event, 2, campaign: create(:campaign, company: campaign.company))

      area = create(:area, company: campaign.company)
      area.places << place
      campaign.areas << area

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save

      area_goal = area.goals.for_kpi(kpi)
      area_goal.parent = campaign
      area_goal.value = 100
      area_goal.save

      xhr :post, 'report', report: { campaign_id: campaign.id }, item_type: 'Area', item_id: area.id, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [area_goal]
    end

    it 'should include only goals for the given place' do
      kpi = create(:kpi, company: campaign.company)
      place = create(:place)
      events = create_list(:event, 3, campaign: campaign, place: place)
      create_list(:event, 2, campaign: create(:campaign, company: campaign.company))

      campaign.add_kpi kpi
      goal = campaign.goals.for_kpi(kpi)
      goal.value = 100
      goal.save

      place_goal = place.goals.for_kpi(kpi)
      place_goal.parent = campaign
      place_goal.value = 100
      place_goal.save

      xhr :post, 'report', report: { campaign_id: campaign.id }, item_type: 'Place', item_id: place.id, format: :js

      expect(assigns(:events_scope)).to match_array events
      expect(assigns(:goals)).to match_array [place_goal]
    end
  end
end
