# == Schema Information
#
# Table name: campaigns
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  description    :text
#  aasm_state     :string(255)
#  created_by_id  :integer
#  updated_by_id  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :integer
#  first_event_id :integer
#  last_event_id  :integer
#  first_event_at :datetime
#  last_event_at  :datetime
#

require 'spec_helper'

describe Campaign do
  it { should belong_to(:company) }
  it { should have_many(:memberships) }
  it { should have_many(:users).through(:memberships) }
  it { should have_and_belong_to_many(:brands) }
  it { should have_and_belong_to_many(:brand_portfolios) }
  it { should have_and_belong_to_many(:areas) }
  it { should have_and_belong_to_many(:date_ranges) }
  it { should have_and_belong_to_many(:day_parts) }

  it { should validate_presence_of(:name) }

  describe "states" do
    before(:each) do
      @campaign = FactoryGirl.create(:campaign)
    end

    describe ":inactive" do
      it 'should be an initial state' do
        @campaign.should be_active
      end

      it 'should change to :inactive on :active' do
        @campaign.deactivate
        @campaign.should be_inactive
      end

      it 'should change to :active on :inactive or :closed' do
        @campaign.deactivate
        @campaign.activate
        @campaign.should be_active
      end
    end
  end

  describe "Get first and last events for a campaign" do
    describe "#first_event" do
      before(:each) do
        @campaign = FactoryGirl.create(:campaign)
        @first_event = FactoryGirl.create(:event, company: @campaign.company, campaign: @campaign, start_date: '05/02/2019', start_time: '10:00am', end_date: '05/02/2019', end_time: '06:00pm')
        @second_event = FactoryGirl.create(:event, company: @campaign.company, campaign: @campaign, start_date: '05/03/2019', start_time: '08:00am', end_date: '05/03/2019', end_time: '12:00pm')
        @third_event = FactoryGirl.create(:event, company: @campaign.company, campaign: @campaign, start_date: '05/04/2019', start_time: '01:00pm', end_date: '05/04/2019', end_time: '03:00pm')
        @campaign.reload
      end

      it "should return the first event related to the campaign" do
        @campaign.first_event.should == @first_event
      end

      it "should return the last event related to the campaign" do
        @campaign.last_event.should == @third_event
      end
    end
  end

  describe "brands_list=" do
    it "should create any non-existing brand into the app" do
      campaign = FactoryGirl.build(:campaign, brands_list: 'Brand 1,Brand 2,Brand 3')
      expect{
        campaign.save!
      }.to change(Brand, :count).by(3)
      campaign.reload.brands.map(&:name).should == ['Brand 1','Brand 2','Brand 3']
    end

    it "should create only the brands that does not exists into the app" do
      FactoryGirl.create(:brand, name: 'Brand 1')
      campaign = FactoryGirl.build(:campaign, brands_list: 'Brand 1,Brand 2,Brand 3')
      expect{
        campaign.save!
      }.to change(Brand, :count).by(2)
      campaign.reload.brands.map(&:name).should == ['Brand 1','Brand 2','Brand 3']
      Brand.all.map(&:name).should =~ ['Brand 1','Brand 2','Brand 3']
    end

    it "should remove any other brand from the campaign not in the new list" do
      campaign = FactoryGirl.create(:campaign, brands_list: 'Brand 1,Brand 2,Brand 3')
      campaign.reload.brands.count.should == 3
      expect{
        campaign.brands_list = 'Brand 2,Brand 1'
        campaign.save!
      }.to_not change(Brand, :count)
      campaign.reload.brands.map(&:name).should == ['Brand 1','Brand 2']
      Brand.all.map(&:name).should =~ ['Brand 1','Brand 2','Brand 3']
    end
  end

  describe "brands_list" do
    it "should return the brands on a list separated by comma" do
      campaign = FactoryGirl.create(:campaign)
      campaign.brands << FactoryGirl.create(:brand,  name: 'Brand 1')
      campaign.brands << FactoryGirl.create(:brand,  name: 'Brand 2')
      campaign.brands << FactoryGirl.create(:brand,  name: 'Brand 3')
      campaign.brands_list.should == 'Brand 1,Brand 2,Brand 3'
    end
  end


  describe "staff_users" do
    it "should include users that have the brands assigned to" do
      brand = FactoryGirl.create(:brand)
      campaign = FactoryGirl.create(:campaign, brand_ids: [brand.id], company_id: 1)

      # This is an user that is following all the campaigns of this brand
      user = FactoryGirl.create(:company_user, brand_ids: [brand.id], company_id: 1)

      # Create another user related to another brand
      FactoryGirl.create(:company_user, brand_ids: [FactoryGirl.create(:brand).id], company_id: 1)

      campaign.staff_users.should == [user]
    end

    it "should include users that have the brand portfolios assigned to" do
      brand_portfolio = FactoryGirl.create(:brand_portfolio)
      campaign = FactoryGirl.create(:campaign, brand_portfolio_ids: [brand_portfolio.id], company_id: 1)

      # This is an user that is following all the campaigns of this brand
      user = FactoryGirl.create(:company_user, brand_portfolio_ids: [brand_portfolio.id], company_id: 1)

      # Create another user related to another brand portfolio
      FactoryGirl.create(:company_user, brand_portfolio_ids: [FactoryGirl.create(:brand_portfolio).id], company_id: 1)

      campaign.staff_users.should == [user]
    end

    it "should include users that are directly assigned to the campaign" do
      campaign = FactoryGirl.create(:campaign, company_id: 1)

      # This is an user that is assgined to the campaign
      user = FactoryGirl.create(:company_user, company_id: 1)

      campaign.users << user

      campaign.staff_users.should == [user]
    end

    it "mixup between the diferent sources" do
      brand_portfolio = FactoryGirl.create(:brand_portfolio)
      brand = FactoryGirl.create(:brand)
      brand2 = FactoryGirl.create(:brand)
      campaign = FactoryGirl.create(:campaign, brand_portfolio_ids: [brand_portfolio.id], brand_ids: [brand.id, brand2.id], company_id: 1)

      # This is an user that is following all the campaigns of this brand
      user = FactoryGirl.create(:company_user, brand_portfolio_ids: [brand_portfolio.id], brand_ids: [brand.id], company_id: 1)
      user2 = FactoryGirl.create(:company_user, brand_ids: [brand2.id], company_id: 1)

      # Create another user related to another brand portfolio
      FactoryGirl.create(:company_user, brand_portfolio_ids: [FactoryGirl.create(:brand_portfolio).id], company_id: 1)

      campaign.staff_users.should =~ [user, user2]
    end
  end

  describe "place_allowed_for_event?" do
    let(:campaign) { FactoryGirl.create(:campaign) }

    it "should return true if the campaing doesn't have areas or places assigned" do
      place = FactoryGirl.create(:place)
      campaign.place_allowed_for_event?(place).should be_true
    end

    it "should return true if the place have been assigned to the campaign directly" do
      place = FactoryGirl.create(:place)
      other_place = FactoryGirl.create(:place)
      campaign.places << other_place

      campaign.place_allowed_for_event?(place).should be_false

      campaign.places << place

      campaign.reload.place_allowed_for_event?(place).should be_true
    end

    it "should return true if the place is part of any of the campaigns" do
      area = FactoryGirl.create(:area)
      place = FactoryGirl.create(:place, country: 'CR')
      other_place = FactoryGirl.create(:place, country: 'US')
      area.places << other_place
      campaign.areas << area

      campaign.place_allowed_for_event?(place).should be_false

      area.places << place

      campaign.reload.place_allowed_for_event?(place).should be_true
    end

    it "should return true if the place is part of any city of an area associated to the campaign" do
      area =  FactoryGirl.create(:area)
      city =  FactoryGirl.create(:place, types: ['locality'], city: 'San Francisco', state: 'California', country: 'US')
      place = FactoryGirl.create(:place, types: ['establishment'], city: 'San Francisco', state: 'California', country: 'US')
      other_city = FactoryGirl.create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << other_city
      campaign.areas << area

      campaign.place_allowed_for_event?(place).should be_false

      # Assign San Francisco to the area
      area.places << city

      # Because the campaing cache the locations, load a new object with the same campaign ID
      Campaign.find(campaign.id).place_allowed_for_event?(place).should be_true
    end

    it "should work with places that are not yet saved" do
      area =  FactoryGirl.create(:area)
      city =  FactoryGirl.create(:place, types: ['locality'], city: 'San Francisco', state: 'California', country: 'US')
      place = FactoryGirl.build(:place, types: ['establishment'], city: 'San Francisco', state: 'California', country: 'US')
      campaign.areas << area

      # Assign San Francisco to the area
      area.places << city

      # Because the campaing cache the locations, load a new object with the same campaign ID
      campaign.place_allowed_for_event?(place).should be_true
    end
  end

  describe "#promo_hours_graph_data" do
    before(:each) do
      Kpi.create_global_kpis
    end
    it "should return empty when there are no campaigns and events" do
      stats = Campaign.promo_hours_graph_data
      expect(stats).to be_empty
    end

    it "should return empty when there are campaigns but no goals" do
      campaign = FactoryGirl.create(:campaign)
      stats = Campaign.promo_hours_graph_data
      expect(stats).to be_empty
    end

    it "should the stats for events kpi if the campaign has goals" do
      campaign = FactoryGirl.create(:campaign, name: 'TestCmp1')
      campaign.goals.for_kpi(Kpi.events).value = 10
      campaign.save

      event = FactoryGirl.create(:approved_event, campaign: campaign)

      stats = Campaign.promo_hours_graph_data
      expect(stats.count).to eql 1
      expect(stats.first['id']).to eql campaign.id
      expect(stats.first['name']).to eql 'TestCmp1'
      expect(stats.first['kpi']).to eql 'EVENTS'
      expect(stats.first['goal']).to eql 10.0
      expect(stats.first['executed']).to eql 1.0
      expect(stats.first['scheduled']).to eql 0.0
      expect(stats.first['remaining']).to eql 9.0
      expect(stats.first['executed_percentage']).to eql 10
      expect(stats.first['scheduled_percentage']).to eql 0
      expect(stats.first['remaining_percentage']).to eql 90
    end

    it "should the stats for promo_hours kpi if the campaign has goals" do
      campaign = FactoryGirl.create(:campaign, name: 'TestCmp1')
      campaign.goals.for_kpi(Kpi.promo_hours).value = 10
      campaign.save

      event = FactoryGirl.create(:approved_event, start_time: '8:00pm', end_time: '11:00pm', campaign: campaign)

      stats = Campaign.promo_hours_graph_data
      expect(stats.count).to eql 1
      expect(stats.first['id']).to eql campaign.id
      expect(stats.first['name']).to eql 'TestCmp1'
      expect(stats.first['kpi']).to eql 'PROMO HOURS'
      expect(stats.first['goal']).to eql 10.0
      expect(stats.first['executed']).to eql 3.0
      expect(stats.first['scheduled']).to eql 0.0
      expect(stats.first['remaining']).to eql 7.0
      expect(stats.first['executed_percentage']).to eql 30
      expect(stats.first['scheduled_percentage']).to eql 0
      expect(stats.first['remaining_percentage']).to eql 70
    end

    it "should the stats for promo_hours and events kpi if the campaign has goals for both kpis" do
      campaign = FactoryGirl.create(:campaign, name: 'TestCmp1')
      campaign.goals.for_kpi(Kpi.promo_hours).value = 10
      campaign.goals.for_kpi(Kpi.events).value = 5
      campaign.save

      event = FactoryGirl.create(:approved_event, start_time: '8:00pm', end_time: '11:00pm', campaign: campaign)

      stats = Campaign.promo_hours_graph_data
      expect(stats.count).to eql 2
      expect(stats.first['id']).to eql campaign.id
      expect(stats.first['name']).to eql 'TestCmp1'
      expect(stats.first['kpi']).to eql 'PROMO HOURS'
      expect(stats.first['goal']).to eql 10.0
      expect(stats.first['executed']).to eql 3.0
      expect(stats.first['scheduled']).to eql 0.0
      expect(stats.first['remaining']).to eql 7.0
      expect(stats.first['executed_percentage']).to eql 30
      expect(stats.first['scheduled_percentage']).to eql 0
      expect(stats.first['remaining_percentage']).to eql 70

      expect(stats.last['id']).to eql campaign.id
      expect(stats.last['name']).to eql 'TestCmp1'
      expect(stats.last['kpi']).to eql 'EVENTS'
      expect(stats.last['goal']).to eql 5.0
      expect(stats.last['executed']).to eql 1.0
      expect(stats.last['scheduled']).to eql 0.0
      expect(stats.last['remaining']).to eql 4.0
      expect(stats.last['executed_percentage']).to eql 20
      expect(stats.last['scheduled_percentage']).to eql 0
      expect(stats.last['remaining_percentage']).to eql 80
    end

    it "should count rejected, new and submitted events as scheduled" do
      campaign = FactoryGirl.create(:campaign, name: 'TestCmp1')
      campaign.goals.for_kpi(Kpi.promo_hours).value = 10
      campaign.goals.for_kpi(Kpi.events).value = 5
      campaign.save

      event = FactoryGirl.create(:approved_event, start_time: '8:00pm', end_time: '11:00pm', campaign: campaign)
      event = FactoryGirl.create(:rejected_event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)
      event = FactoryGirl.create(:submitted_event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)
      event = FactoryGirl.create(:event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)

      stats = Campaign.promo_hours_graph_data
      expect(stats.count).to eql 2
      expect(stats.first['id']).to eql campaign.id
      expect(stats.first['name']).to eql 'TestCmp1'
      expect(stats.first['kpi']).to eql 'PROMO HOURS'
      expect(stats.first['goal']).to eql 10.0
      expect(stats.first['executed']).to eql 3.0
      expect(stats.first['scheduled']).to eql 3.0
      expect(stats.first['remaining']).to eql 4.0
      expect(stats.first['executed_percentage']).to eql 30
      expect(stats.first['scheduled_percentage']).to eql 30
      expect(stats.first['remaining_percentage']).to eql 40

      expect(stats.last['id']).to eql campaign.id
      expect(stats.last['name']).to eql 'TestCmp1'
      expect(stats.last['kpi']).to eql 'EVENTS'
      expect(stats.last['goal']).to eql 5.0
      expect(stats.last['executed']).to eql 1.0
      expect(stats.last['scheduled']).to eql 3.0
      expect(stats.last['remaining']).to eql 1.0
      expect(stats.last['executed_percentage']).to eql 20
      expect(stats.last['scheduled_percentage']).to eql 60
      expect(stats.last['remaining_percentage']).to eql 20
    end

    it "should set the today values correctly" do
      campaign = FactoryGirl.create(:campaign, name: 'TestCmp1', start_date: '01/01/2014', end_date: '02/01/2014')
      campaign.goals.for_kpi(Kpi.promo_hours).value = 10
      campaign.goals.for_kpi(Kpi.events).value = 5
      campaign.save

      event = FactoryGirl.create(:approved_event, start_time: '8:00pm', end_time: '11:00pm', campaign: campaign)
      event = FactoryGirl.create(:event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)
      event = FactoryGirl.create(:event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)
      event = FactoryGirl.create(:event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)

      Timecop.travel Date.new(2014, 01, 15) do
        stats = Campaign.promo_hours_graph_data
        expect(stats.count).to eql 2
        expect(stats.first['kpi']).to eql 'PROMO HOURS'
        expect(stats.first['today']).to eql 4.838709677419355
        expect(stats.first['today_percentage']).to eql 48

        expect(stats.last['kpi']).to eql 'EVENTS'
        expect(stats.last['today']).to eql 2.4193548387096775
        expect(stats.last['today_percentage']).to eql 48
      end

      Timecop.travel Date.new(2014, 01, 25) do
        stats = Campaign.promo_hours_graph_data
        expect(stats.count).to eql 2
        expect(stats.first['kpi']).to eql 'PROMO HOURS'
        expect(stats.first['today']).to eql 8.064516129032258
        expect(stats.first['today_percentage']).to eql 80

        expect(stats.last['kpi']).to eql 'EVENTS'
        expect(stats.last['today']).to eql 4.032258064516129
        expect(stats.last['today_percentage']).to eql 80
      end

      # When the campaing end date is before the current date
      Timecop.travel Date.new(2014, 02, 25) do
        stats = Campaign.promo_hours_graph_data
        expect(stats.count).to eql 2
        expect(stats.first['kpi']).to eql 'PROMO HOURS'
        expect(stats.first['today']).to eql 10.0
        expect(stats.first['today_percentage']).to eql 100

        expect(stats.last['kpi']).to eql 'EVENTS'
        expect(stats.last['today']).to eql 5.0
        expect(stats.last['today_percentage']).to eql 100
      end


      # When the campaing start date is after the current date
      Timecop.travel Date.new(2013, 12, 25) do
        stats = Campaign.promo_hours_graph_data
        expect(stats.count).to eql 2
        expect(stats.first['kpi']).to eql 'PROMO HOURS'
        expect(stats.first['today']).to eql 0
        expect(stats.first['today_percentage']).to eql 0

        expect(stats.last['kpi']).to eql 'EVENTS'
        expect(stats.last['today']).to eql 0
        expect(stats.last['today_percentage']).to eql 0
      end
    end
  end

  describe "#in_date_range?" do
    it "returns true if both dates are inside the start/end dates" do
      campaign = FactoryGirl.build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2014, 1, 3), Date.new(2014, 1, 23))).to be_true
    end

    it "returns true if start date is inside the start/end dates" do
      campaign = FactoryGirl.build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2014, 1, 3), Date.new(2014, 6, 23))).to be_true
    end

    it "returns true if end date is inside the start/end dates" do
      campaign = FactoryGirl.build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2013, 1, 3), Date.new(2014, 1, 23))).to be_true
    end

    it "returns false if both dates are after the end date" do
      campaign = FactoryGirl.build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2014, 3, 3), Date.new(2014, 3, 23))).to be_false
    end


    it "returns false if both dates are before the start date" do
      campaign = FactoryGirl.build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2013, 1, 3), Date.new(2013, 2, 23))).to be_false
    end
  end

end
