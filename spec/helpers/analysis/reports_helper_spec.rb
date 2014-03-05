require 'spec_helper'

describe Analysis::ReportsHelper do
  before do
    Kpi.create_global_kpis
    @company = FactoryGirl.create(:company)
    @company_user = FactoryGirl.create(:company_user, company: @company)
  end

  describe "#each_events_goal" do
    it "should return the goals results for each campaign KPI and Activity Type" do
      place = FactoryGirl.create(:place)
      activity_type1 = FactoryGirl.create(:activity_type, company: @company)
      activity_type2 = FactoryGirl.create(:activity_type, company: @company)
      campaign = FactoryGirl.create(:campaign, company: @company)
      campaign.assign_all_global_kpis
      campaign.activity_types << activity_type1
      campaign.activity_types << activity_type2
      goals = [
        FactoryGirl.create(:goal, goalable: campaign, kpi_id: Kpi.impressions.id, value: '100'),
        FactoryGirl.create(:goal, goalable: campaign, kpi_id: Kpi.events.id, value: '20'),
        FactoryGirl.create(:goal, goalable: campaign, kpi_id: Kpi.interactions.id, value: '400'),
        FactoryGirl.create(:goal, goalable: campaign, activity_type_id: activity_type1.id, value: '5'),
        FactoryGirl.create(:goal, goalable: campaign, activity_type_id: activity_type2.id, value: '10')
      ]
      event = FactoryGirl.create(:approved_event, company: @company,
        campaign: campaign, place: place,
        results: {impressions: 50, interactions: 160} )
      FactoryGirl.create(:activity, activity_type: activity_type1, activitable: event, company_user: @company_user, campaign: campaign)
      FactoryGirl.create(:activity, activity_type: activity_type2, activitable: event, company_user: @company_user, campaign: campaign)

      helper.instance_variable_set(:@events_scope, Event.where(id: event.id))
      helper.instance_variable_set(:@campaign, campaign)
      helper.instance_variable_set(:@goals, goals)

      results = helper.each_events_goal

      results[1][:goal].kpi_id.should == Kpi.impressions.id
      results[1][:goal].goalable_id.should == campaign.id
      results[1][:completed_percentage].should == 50.0
      results[1][:remaining_percentage].should == 50.0
      results[1][:remaining_count].should == 50.0
      results[1][:total_count].should == 50
      results[1][:submitted].should be_nil

      results[2][:goal].kpi_id.should == Kpi.events.id
      results[2][:goal].goalable_id.should == campaign.id
      results[2][:completed_percentage].should == 5.0
      results[2][:remaining_percentage].should == 95.0
      results[2][:remaining_count].should == 19.0
      results[2][:total_count].should == 1
      results[2][:submitted].should == 0

      results[3][:goal].kpi_id.should == Kpi.interactions.id
      results[3][:goal].goalable_id.should == campaign.id
      results[3][:completed_percentage].should == 40.0
      results[3][:remaining_percentage].should == 60.0
      results[3][:remaining_count].should == 240.0
      results[3][:total_count].should == 160
      results[3][:submitted].should be_nil

      results[4][:goal].activity_type_id.should == activity_type1.id
      results[4][:goal].goalable_id.should == campaign.id
      results[4][:completed_percentage].should == 20.0
      results[4][:remaining_percentage].should == 80.0
      results[4][:remaining_count].should == 4.0
      results[4][:total_count].should == 1
      results[4][:submitted].should == 0

      results[5][:goal].activity_type_id.should == activity_type2.id
      results[5][:goal].goalable_id.should == campaign.id
      results[5][:completed_percentage].should == 10.0
      results[5][:remaining_percentage].should == 90.0
      results[5][:remaining_count].should == 9.0
      results[5][:total_count].should == 1
      results[5][:submitted].should == 0
    end
  end
end