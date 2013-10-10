require 'spec_helper'

describe DashboardHelper do
  before(:all) do
    Kpi.destroy_all
    Kpi.create_global_kpis
  end
  before do
    @company = FactoryGirl.create(:company)
    @current_company_user = FactoryGirl.create(:company_user, company: @company, role: FactoryGirl.create(:role, is_admin: true))
    helper.stub(:current_company) { @company }
    helper.stub(:current_company_user) { @current_company_user }
    Sunspot.commit
  end
  describe "#kpi_trends_stats", search: true do
    it "should return all values in zero when there are no campaigns and events" do
      stats = helper.kpi_trends_stats(Kpi.events)
      stats[:goal].should  == 0
      stats[:completed].should  == 0
      stats[:remaining].should  == 0
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 0
      stats[:today_percentage].should  == 0
    end

    it "should return all values in zero when there are campaigns but no events" do
      campaign = FactoryGirl.create(:campaign, company: @company)

      Sunspot.commit
      stats = helper.kpi_trends_stats(Kpi.events)
      stats[:goal].should  == 0
      stats[:completed].should  == 0
      stats[:remaining].should  == 0
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 0
      stats[:today_percentage].should  == 0
    end


    it "should return all values in zero when there are no approved events" do
      campaign = FactoryGirl.create(:campaign, company: @company)

      event = FactoryGirl.create(:event, company: @company, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Benito'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 1000}])

      Sunspot.commit

      stats = helper.kpi_trends_stats(Kpi.events)
      stats[:goal].should  == 0
      stats[:completed].should  == 0
      stats[:remaining].should  == 0
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 0
      stats[:today_percentage].should  == 0
    end

    it "should return the goals and the remainging totals correctly based on the campaign goals" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      campaign.goals.for_kpi(Kpi.events).value = 10
      campaign.goals.for_kpi(Kpi.promo_hours).value = 11
      campaign.goals.for_kpi(Kpi.impressions).value = 12
      campaign.goals.for_kpi(Kpi.interactions).value = 13
      campaign.goals.for_kpi(Kpi.samples).value = 14
      campaign.goals.for_kpi(Kpi.expenses).value = 15
      campaign.save

      Sunspot.commit

      stats = helper.kpi_trends_stats(Kpi.events)
      stats[:goal].should  == 10
      stats[:completed].should  == 0
      stats[:remaining].should  == 10
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.promo_hours)
      stats[:goal].should  == 11
      stats[:completed].should  == 0
      stats[:remaining].should  == 11
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.impressions)
      stats[:goal].should  == 12
      stats[:completed].should  == 0
      stats[:remaining].should  == 12
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.interactions)
      stats[:goal].should  == 13
      stats[:completed].should  == 0
      stats[:remaining].should  == 13
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.samples)
      stats[:goal].should  == 14
      stats[:completed].should  == 0
      stats[:remaining].should  == 14
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.expenses)
      stats[:goal].should  == 15
      stats[:completed].should  == 0
      stats[:remaining].should  == 15
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100
    end

    it "should return the goals and the remainging totals of all the campaings" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      campaign.goals.for_kpi(Kpi.events).value = 10
      campaign.goals.for_kpi(Kpi.promo_hours).value = 11
      campaign.goals.for_kpi(Kpi.impressions).value = 12
      campaign.goals.for_kpi(Kpi.interactions).value = 13
      campaign.goals.for_kpi(Kpi.samples).value = 14
      campaign.goals.for_kpi(Kpi.expenses).value = 15
      campaign.save

      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign,
          start_date: "01/23/2019", start_time: "10:00am",
          end_date:   "01/23/2019",   end_time: "12:00pm",
          results: {impressions: 5, interactions: 6, samples: 7},
          expenses: [{name: 'Expense 1', amount: 8}])

      campaign = FactoryGirl.create(:campaign, company: @company)
      campaign.goals.for_kpi(Kpi.events).value = 20
      campaign.goals.for_kpi(Kpi.promo_hours).value = 21
      campaign.goals.for_kpi(Kpi.impressions).value = 22
      campaign.goals.for_kpi(Kpi.interactions).value = 23
      campaign.goals.for_kpi(Kpi.samples).value = 24
      campaign.goals.for_kpi(Kpi.expenses).value = 25
      campaign.save

      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign,
          start_date: "01/23/2019", start_time: "10:00am",
          end_date:   "01/23/2019",   end_time: "11:00am",
          results: {impressions: 15, interactions: 16, samples: 17},
          expenses: [{name: 'Expense 1', amount: 18}])


      # Create NOT approved events that should not be included on the results
      event = FactoryGirl.create(:rejected_event, company: @company, campaign: campaign,
          start_date: "01/23/2019", start_time: "10:00am",
          end_date:   "01/23/2019",   end_time: "11:00am",
          results: {impressions: 15, interactions: 16, samples: 17},
          expenses: [{name: 'Expense 1', amount: 18}])


      # Create NOT approved events that should not be included on the results
      event = FactoryGirl.create(:submitted_event, company: @company, campaign: campaign,
          start_date: "01/23/2019", start_time: "10:00am",
          end_date:   "01/23/2019",   end_time: "11:00am",
          results: {impressions: 15, interactions: 16, samples: 17},
          expenses: [{name: 'Expense 1', amount: 18}])


      Sunspot.commit

      stats = helper.kpi_trends_stats(Kpi.events)
      stats[:goal].should  == 30
      stats[:completed].should  == 2
      stats[:remaining].should  == 28
      stats[:completed_percentage].should  == 6
      stats[:remaining_percentage].should  == 94

      stats = helper.kpi_trends_stats(Kpi.promo_hours)
      stats[:goal].should  == 32
      stats[:completed].should  == 3
      stats[:remaining].should  == 29
      stats[:completed_percentage].should  == 9
      stats[:remaining_percentage].should  == 91

      stats = helper.kpi_trends_stats(Kpi.impressions)
      stats[:goal].should  == 34
      stats[:completed].should  == 20
      stats[:remaining].should  == 14
      stats[:completed_percentage].should  == 59
      stats[:remaining_percentage].should  == 41

      stats = helper.kpi_trends_stats(Kpi.interactions)
      stats[:goal].should  == 36
      stats[:completed].should  == 22
      stats[:remaining].should  == 14
      stats[:completed_percentage].should  == 61
      stats[:remaining_percentage].should  == 39

      stats = helper.kpi_trends_stats(Kpi.samples)
      stats[:goal].should  == 38
      stats[:completed].should  == 24
      stats[:remaining].should  == 14
      stats[:completed_percentage].should  == 63
      stats[:remaining_percentage].should  == 37

      stats = helper.kpi_trends_stats(Kpi.expenses)
      stats[:goal].should  == 40
      stats[:completed].should  == 26
      stats[:remaining].should  == 14
      stats[:completed_percentage].should  == 65
      stats[:remaining_percentage].should  == 35
    end


    it "should return the results of approved events acrross all campaings" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      campaign.goals.for_kpi(Kpi.events).value = 10
      campaign.goals.for_kpi(Kpi.promo_hours).value = 11
      campaign.goals.for_kpi(Kpi.impressions).value = 12
      campaign.goals.for_kpi(Kpi.interactions).value = 13
      campaign.goals.for_kpi(Kpi.samples).value = 14
      campaign.goals.for_kpi(Kpi.expenses).value = 15
      campaign.save

      campaign = FactoryGirl.create(:campaign, company: @company)
      campaign.goals.for_kpi(Kpi.events).value = 20
      campaign.goals.for_kpi(Kpi.promo_hours).value = 21
      campaign.goals.for_kpi(Kpi.impressions).value = 22
      campaign.goals.for_kpi(Kpi.interactions).value = 23
      campaign.goals.for_kpi(Kpi.samples).value = 24
      campaign.goals.for_kpi(Kpi.expenses).value = 25
      campaign.save

      Sunspot.commit

      stats = helper.kpi_trends_stats(Kpi.events)
      stats[:goal].should  == 30
      stats[:completed].should  == 0
      stats[:remaining].should  == 30
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.promo_hours)
      stats[:goal].should  == 32
      stats[:completed].should  == 0
      stats[:remaining].should  == 32
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.impressions)
      stats[:goal].should  == 34
      stats[:completed].should  == 0
      stats[:remaining].should  == 34
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.interactions)
      stats[:goal].should  == 36
      stats[:completed].should  == 0
      stats[:remaining].should  == 36
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.samples)
      stats[:goal].should  == 38
      stats[:completed].should  == 0
      stats[:remaining].should  == 38
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100

      stats = helper.kpi_trends_stats(Kpi.expenses)
      stats[:goal].should  == 40
      stats[:completed].should  == 0
      stats[:remaining].should  == 40
      stats[:completed_percentage].should  == 0
      stats[:remaining_percentage].should  == 100
    end
  end

  describe "#dashboard_kpis_trends_data" do
    it "should return all values on zero if there are not campaigns and events" do
      stats = helper.dashboard_kpis_trends_data
      stats[:events].should == 0
      stats[:impressions].should == 0
      stats[:interactions].should == 0
      stats[:spent].should == 0
    end

    it "should return all values of all approved events" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      event = FactoryGirl.create(:approved_event, company: @company, campaign: campaign,
          start_date: "01/23/2019", start_time: "10:00am",
          end_date:   "01/23/2019",   end_time: "11:00am",
          results: {impressions: 15, interactions: 16, samples: 17},
          expenses: [{name: 'Expense 1', amount: 18}])

      stats = helper.dashboard_kpis_trends_data

      stats[:events].should == 1
      stats[:impressions].should == 15
      stats[:interactions].should == 16
      stats[:spent].should == 18
      stats[:impressions_event].should == 15
      stats[:interactions_event].should == 16
      stats[:sampled_event].should == 17
      stats[:cost_impression].should == 1.2
      stats[:cost_interaction].should == 1.125
      stats[:cost_sample].should == 1.0588235294117647
    end
  end

end