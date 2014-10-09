require 'rails_helper'

describe Analysis::CampaignsReportController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
    # Kpi.create_global_kpis
  end

  describe "GET 'index'" do
    it 'should load all the current campaign ' do
      campaigns = []
      campaigns.push create(:campaign, company: @company)
      campaigns.push create(:inactive_campaign, company: @company)

      get 'index'

      expect(response).to be_success
      expect(assigns(:campaigns)).to eq(campaigns)
    end
  end

  describe "GET 'index'" do
    let(:campaign) { create(:campaign, company: @company) }

    it 'should render the campaign report' do
      xhr :get, 'report', report: { campaign_id: campaign.to_param }, format: :js
      expect(response).to be_success
    end

    it 'should assign the correct scope to @events_scope' do
      Kpi.create_global_kpis
      events = create_list(:approved_event, 3, company: @company, campaign: campaign)
      create(:event, company: @company, campaign: campaign)
      create(:approved_event, company: @company, campaign_id: campaign.id + 1)
      create(:approved_event, company_id: @company.id + 1, campaign_id: campaign.id + 1)

      xhr :get, 'report', report: { campaign_id: campaign.to_param }, format: :js

      expect(response).to be_success
      expect(assigns(:events_scope)).to match_array(events)
    end

    it "should load all the campaign's goals into @goals" do
      Kpi.create_global_kpis
      campaign.assign_all_global_kpis
      goals = [
        create(:goal, goalable: campaign, kpi_id: Kpi.impressions.id),
        create(:goal, goalable: campaign, kpi_id: Kpi.events.id),
        create(:goal, goalable: campaign, kpi_id: Kpi.interactions.id)
      ]

      xhr :get, 'report', report: { campaign_id: campaign.to_param }, format: :js

      expect(response).to be_success
      expect(assigns(:goals)).to match_array(goals)
    end
  end
end
