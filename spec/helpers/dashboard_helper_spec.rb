require 'spec_helper'

describe DashboardHelper do
  before do
    Kpi.create_global_kpis
    @company = FactoryGirl.create(:company)
    @current_company_user = FactoryGirl.create(:company_user, company: @company, role: FactoryGirl.create(:role, is_admin: true))
    helper.stub(:current_company) { @company }
    helper.stub(:current_company_user) { @current_company_user }
    Sunspot.commit
  end

  describe "#kpis_completed_totals", search: true do
    it "should return all values on zero if there are not campaigns and events" do
      stats = helper.kpis_completed_totals
      stats['events_count'].should == 0
      stats['impressions'].should == 0
      stats['interactions'].should == 0
      stats['spent'].should == 0
      stats['samples'].should == 0
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

      stats['events_count'].should == 1
      stats['impressions'].should == 15
      stats['interactions'].should == 16
      stats['spent'].should == 18
      stats['samples'].should == 17
      stats['impressions_event'].should == 15
      stats['interactions_event'].should == 16
      stats['sampled_event'].should == 17
      stats['cost_impression'].should == 1.2
      stats['cost_interaction'].should == 1.125
      stats['cost_sample'].should == 1.0588235294117647
    end
  end

end