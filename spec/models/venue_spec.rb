# encoding: utf-8
# == Schema Information
#
# Table name: venues
#
#  id                   :integer          not null, primary key
#  company_id           :integer
#  place_id             :integer
#  events_count         :integer
#  promo_hours          :decimal(8, 2)    default(0.0)
#  impressions          :integer
#  interactions         :integer
#  sampled              :integer
#  spent                :decimal(10, 2)   default(0.0)
#  score                :integer
#  avg_impressions      :decimal(8, 2)    default(0.0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  avg_impressions_hour :decimal(6, 2)    default(0.0)
#  avg_impressions_cost :decimal(8, 2)    default(0.0)
#  score_impressions    :integer
#  score_cost           :integer
#

require 'spec_helper'

describe Venue do
  it { should belong_to(:place) }
  it { should belong_to(:company) }

  describe "compute_stats" do
    let(:company) { FactoryGirl.create(:company) }
    let(:venue) { FactoryGirl.create(:venue, company: company, place: FactoryGirl.create(:place)) }

    it "return succeed if there are no events for this venue" do
      venue.compute_stats.should be_true
    end

    it "count the number of events for the company" do
      venue.save
      e = FactoryGirl.create(:event, place_id: venue.place_id, company: company, start_date: "01/23/2019", end_date: "01/23/2019", start_time: '8:00am', end_time: '11:00am')
      FactoryGirl.create(:event, company: company, place_id: FactoryGirl.create(:place).id) # Create another event for other place
      FactoryGirl.create(:event, place_id: venue.place_id) # Create another event for other company

      venue.compute_stats
      venue.reload
      venue.events_count.should == 1
      venue.promo_hours.to_i.should == 3

      # TODO: test the values for impressions, interactions and other kpis values
    end
  end

  describe "compute_scoring", search: true do
    it "should correctly compute the scoring based on the venues in a radius of 5KM" do
      place1 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, latitude: 9.930713, longitude: -84.050045),
        avg_impressions_hour: 142, avg_impressions_cost: 167)
      place2 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, latitude: 9.929967, longitude: -84.047492),
        avg_impressions_hour: 183, avg_impressions_cost: 217)
      place3 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, latitude: 9.931795, longitude: -84.044348),
        avg_impressions_hour: 217, avg_impressions_cost: 183)
      place4 = FactoryGirl.create(:venue, place: FactoryGirl.create(:place, latitude: 9.931795, longitude: -84.044348),
        avg_impressions_hour: 167, avg_impressions_cost: 142)

      Sunspot.commit

      place1.compute_scoring
      place1.score_impressions.should == 13
      place1.score_cost.should == 63
      place1.score.should == 38

      place2.compute_scoring
      place2.score_impressions.should == 57
      place2.score_cost.should == 10
      place2.score.should == 33

      place3.compute_scoring
      place3.score_impressions.should == 90
      place3.score_cost.should == 43
      place3.score.should == 66

      place4.compute_scoring
      place4.score_impressions.should == 37
      place4.score_cost.should == 87
      place4.score.should == 62

    end

    describe "#overall_graphs_data" do
      let(:campaign) { FactoryGirl.create(:campaign) }
      let(:venue) { FactoryGirl.create(:venue, company_id: campaign.company_id, place: FactoryGirl.create(:place)) }

      it "should correctly count the amounts for :age, :gender and :ethnicity" do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis
        event = FactoryGirl.create(:event, campaign: campaign, place_id: venue.place_id, start_date: "01/23/2013", end_date: "01/23/2013", start_time: '6:00pm', end_time: '9:00pm')
        set_event_results(event,
          gender_male: 35,
          gender_female: 65,
          ethnicity_asian: 15,
          ethnicity_native_american: 23,
          ethnicity_black: 24,
          ethnicity_hispanic: 26,
          ethnicity_white: 12,
          age_12: 1,
          age_12_17: 2,
          age_18_24: 4,
          age_25_34: 8,
          age_35_44: 16,
          age_45_54: 32,
          age_55_64: 24,
          age_65: 13
        )
        data = venue.overall_graphs_data

        data[:age].should == {"< 12"=>1.0, "12 – 17"=>2.0, "18 – 24"=>4.0, "25 – 34"=>8.0, "35 – 44"=>16.0, "45 – 54"=>32.0, "55 – 64"=>24.0, "65+"=>13.0}
        data[:gender].should == {"Female"=>65.0, "Male"=>35.0}
        data[:ethnicity].should == {"Asian"=>15.0, "Black / African American"=>24.0, "Hispanic / Latino"=>26.0, "Native American"=>23.0, "White"=>12.0}

      end

      it "should correctly distribute the promo hours for events happening in the same day" do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis
        event = FactoryGirl.create(:event, campaign: campaign, place_id: venue.place_id, start_date: "01/23/2013", end_date: "01/23/2013", start_time: '6:00pm', end_time: '9:00pm')
        set_event_results(event, impressions: 100)

        event = FactoryGirl.create(:event, campaign: campaign, place_id: venue.place_id, start_date: "01/24/2013", end_date: "01/24/2013", start_time: '8:00pm', end_time: '10:00pm')
        set_event_results(event, impressions: 50)

        data = venue.overall_graphs_data
        data[:impressions_promo][0].round.should == 0
        data[:impressions_promo][1].round.should == 0
        data[:impressions_promo][2].round.should == 33  # 100 impressions / 3h
        data[:impressions_promo][3].round.should == 25  # 50 impressions / 2h
        data[:impressions_promo][4].round.should == 0
        data[:impressions_promo][5].round.should == 0
        data[:impressions_promo][6].round.should == 0

      end

      it "should correctly distribute the promo hours for events happening in more than one day" do
        Kpi.create_global_kpis
        campaign.assign_all_global_kpis
        event = FactoryGirl.create(:event, campaign: campaign, place_id: venue.place_id, start_date: "01/23/2013", end_date: "01/24/2013", start_time: '8:00pm', end_time: '03:00am')
        event.event_expenses.create(amount: 1000, name: 'Test expense')
        set_event_results(event, impressions: 100)

        data = venue.overall_graphs_data
        data[:impressions_promo][0].round.should == 0
        data[:impressions_promo][1].round.should == 0
        data[:impressions_promo][2].round.should == 57   # 4h * 100 / 7h
        data[:impressions_promo][3].round.should == 43   # 3h * 100 / 7h
        data[:impressions_promo][4].round.should == 0
        data[:impressions_promo][5].round.should == 0
        data[:impressions_promo][6].round.should == 0

        data[:cost_impression][0].round.should == 0
        data[:cost_impression][1].round.should == 0
        data[:cost_impression][2].round.should == 10   # 1000 / 100
        data[:cost_impression][3].round.should == 10   # 1000 / 100
        data[:cost_impression][4].round.should == 0
        data[:cost_impression][5].round.should == 0
        data[:cost_impression][6].round.should == 0
      end
    end
  end
end
