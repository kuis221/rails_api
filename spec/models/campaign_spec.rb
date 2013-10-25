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
        @first_event = FactoryGirl.create(:event, campaign_id: @campaign.id, start_date: '05/02/2019', start_time: '10:00am', end_date: '05/02/2019', end_time: '06:00pm', company_id: 1)
        @second_event = FactoryGirl.create(:event, campaign_id: @campaign.id, start_date: '05/03/2019', start_time: '08:00am', end_date: '05/03/2019', end_time: '12:00pm', company_id: 1)
        @third_event = FactoryGirl.create(:event, campaign_id: @campaign.id, start_date: '05/04/2019', start_time: '01:00pm', end_date: '05/04/2019', end_time: '03:00pm', company_id: 1)
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

end
