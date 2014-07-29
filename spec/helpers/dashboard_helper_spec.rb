require 'spec_helper'

describe DashboardHelper, :type => :helper do
  before do
    Kpi.create_global_kpis
    @company = FactoryGirl.create(:company)
    @current_company_user = FactoryGirl.create(:company_user, company: @company, role: FactoryGirl.create(:role, is_admin: true))
    allow(helper).to receive(:current_company) { @company }
    allow(helper).to receive(:current_company_user) { @current_company_user }
    Sunspot.commit
  end

  describe "#kpis_completed_totals", search: true do
    it "should return all values on zero if there are not campaigns and events" do
      stats = helper.kpis_completed_totals
      expect(stats['events_count']).to eq(0)
      expect(stats['impressions']).to eq(0)
      expect(stats['interactions']).to eq(0)
      expect(stats['spent']).to eq(0)
      expect(stats['samples']).to eq(0)
    end

    it "should return all values of all approved events" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign,
          start_date: "01/23/2019", start_time: "10:00am",
          end_date:   "01/23/2019",   end_time: "11:00am",
          results: {impressions: 15, interactions: 16, samples: 17},
          expenses: [{name: 'Expense 1', amount: 18}])

      Sunspot.commit

      stats = helper.kpis_completed_totals

      expect(stats['events_count']).to eq(1)
      expect(stats['impressions']).to eq(15)
      expect(stats['interactions']).to eq(16)
      expect(stats['spent']).to eq(18)
      expect(stats['samples']).to eq(17)
      expect(stats['impressions_event']).to eq(15)
      expect(stats['interactions_event']).to eq(16)
      expect(stats['sampled_event']).to eq(17)
      expect(stats['cost_impression']).to eq(1.2)
      expect(stats['cost_interaction']).to eq(1.125)
      expect(stats['cost_sample']).to eq(1.0588235294117647)
    end
  end

end