# == Schema Information
#
# Table name: campaigns
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  description      :text
#  aasm_state       :string(255)
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  company_id       :integer
#  first_event_id   :integer
#  last_event_id    :integer
#  first_event_at   :datetime
#  last_event_at    :datetime
#  start_date       :date
#  end_date         :date
#  survey_brand_ids :integer          default([]), is an Array
#  modules          :text
#

require 'rails_helper'

describe Campaign, type: :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to have_many(:memberships) }
  it { is_expected.to have_many(:users).through(:memberships) }
  it { is_expected.to have_many(:areas) }
  it { is_expected.to have_many(:areas_campaigns) }
  it { is_expected.to have_and_belong_to_many(:brands) }
  it { is_expected.to have_and_belong_to_many(:brand_portfolios) }
  it { is_expected.to have_and_belong_to_many(:date_ranges) }
  it { is_expected.to have_and_belong_to_many(:day_parts) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.not_to validate_presence_of(:color) }
  it { is_expected.to allow_value('').for(:color) }
  it { is_expected.to allow_value(nil).for(:color) }
  it { is_expected.to allow_value('#d7a23c').for(:color) }
  it { is_expected.not_to allow_value('d7a23c').for(:color) }
  it { is_expected.not_to allow_value('#123456').for(:color) }

  let(:company) { create(:company) }

  before { Company.current = company }

  describe 'end_after_start validation' do
    subject { Campaign.new(start_date: '01/22/2013') }

    it { is_expected.not_to allow_value('01/21/2013').for(:end_date).with_message('must be after') }
    it { is_expected.to allow_value('01/22/2013').for(:end_date) }
    it { is_expected.to allow_value('01/23/2013').for(:end_date) }
  end

  describe 'states' do
    before(:each) do
      @campaign = create(:campaign)
    end

    describe ':inactive' do
      it 'should be an initial state' do
        expect(@campaign).to be_active
      end

      it 'should change to :inactive on :active' do
        @campaign.deactivate
        expect(@campaign).to be_inactive
      end

      it 'should change to :active on :inactive or :closed' do
        @campaign.deactivate
        @campaign.activate
        expect(@campaign).to be_active
      end
    end
  end

  describe 'Get first and last events for a campaign' do
    describe '#first_event' do
      before(:each) do
        @campaign = create(:campaign)
        @first_event = create(:event, company: @campaign.company, campaign: @campaign, start_date: '05/02/2019', start_time: '10:00am', end_date: '05/02/2019', end_time: '06:00pm')
        @second_event = create(:event, company: @campaign.company, campaign: @campaign, start_date: '05/03/2019', start_time: '08:00am', end_date: '05/03/2019', end_time: '12:00pm')
        @third_event = create(:event, company: @campaign.company, campaign: @campaign, start_date: '05/04/2019', start_time: '01:00pm', end_date: '05/04/2019', end_time: '03:00pm')
        @campaign.reload
      end

      it 'should return the first event related to the campaign' do
        expect(@campaign.first_event).to eq(@first_event)
      end

      it 'should return the last event related to the campaign' do
        expect(@campaign.last_event).to eq(@third_event)
      end
    end
  end

  describe 'active_global_kpis' do
    let(:campaign) { create(:campaign, modules: { 'expenses' => {}, 'comments' => {} }) }

    it 'should returns global kpis + enabled modules' do
      Kpi.create_global_kpis
      create(:form_field_number,
                         fieldable: campaign,
                         kpi: build(:kpi, company_id: campaign.company_id))

      expect(campaign.active_global_kpis).to match_array [Kpi.events, Kpi.promo_hours, Kpi.expenses, Kpi.comments]
    end
  end

  describe 'active_kpis' do
    let(:campaign) { create(:campaign, modules: { 'surveys' => {} }) }
    it 'should returns only events, promo hours and surveys if no custom kpis have been created for campaign' do
      Kpi.create_global_kpis
      expect(campaign.active_kpis).to match_array [Kpi.events, Kpi.promo_hours, Kpi.surveys]
    end

    it 'should returns all kpis + events, promo hours and surveys' do
      Kpi.create_global_kpis
      form_field  = create(:form_field_number,
                                       fieldable: campaign,
                                       kpi: build(:kpi, company_id: campaign.company_id))

      expect(campaign.active_kpis).to match_array [form_field.kpi, Kpi.events, Kpi.promo_hours, Kpi.surveys]
    end
  end

  describe 'custom_kpis' do
    let(:campaign) { create(:campaign) }
    it 'should returns empty if no custom kpis have been created for campaign' do
      Kpi.create_global_kpis
      expect(campaign.custom_kpis).to match_array []
    end

    it 'should returns all custom kpis' do
      Kpi.create_global_kpis
      form_field  = create(:form_field_number,
                                       fieldable: campaign,
                                       kpi: build(:kpi, company_id: campaign.company_id))

      # Other field associated to another campaign
      create(:form_field_number,
                         fieldable: create(:campaign, company_id: campaign.company_id),
                         kpi: build(:kpi, company_id: campaign.company_id))

      expect(campaign.custom_kpis).to match_array [form_field.kpi]
    end
  end

  describe 'brands_list=' do
    it 'should create any non-existing brand into the app' do
      campaign = build(:campaign, brands_list: 'Brand 1,Brand 2,Brand 3')
      expect do
        campaign.save!
      end.to change(Brand, :count).by(3)
      expect(campaign.reload.brands.map(&:name)).to eq(['Brand 1', 'Brand 2', 'Brand 3'])
    end

    it 'should create only the brands that does not exists into the app' do
      create(:brand, name: 'Brand 1', company: company)
      campaign = build(:campaign, brands_list: 'Brand 1,Brand 2,Brand 3')
      expect do
        campaign.save!
      end.to change(Brand, :count).by(2)
      expect(campaign.reload.brands.map(&:name)).to eq(['Brand 1', 'Brand 2', 'Brand 3'])
      expect(Brand.all.map(&:name)).to match_array(['Brand 1', 'Brand 2', 'Brand 3'])
    end

    it 'should remove any other brand from the campaign not in the new list' do
      campaign = create(:campaign, brands_list: 'Brand 1,Brand 2,Brand 3')
      expect(campaign.reload.brands.count).to eq(3)
      expect do
        campaign.brands_list = 'Brand 2,Brand 1'
        campaign.save!
      end.to_not change(Brand, :count)
      expect(campaign.reload.brands.map(&:name)).to eq(['Brand 1', 'Brand 2'])
      expect(Brand.all.map(&:name)).to match_array(['Brand 1', 'Brand 2', 'Brand 3'])
    end
  end

  describe 'brands_list' do
    it 'should return the brands on a list separated by comma' do
      campaign = create(:campaign)
      campaign.brands << create(:brand,  name: 'Brand 1')
      campaign.brands << create(:brand,  name: 'Brand 2')
      campaign.brands << create(:brand,  name: 'Brand 3')
      expect(campaign.brands_list).to eq('Brand 1,Brand 2,Brand 3')
    end
  end

  describe 'staff_users' do
    it 'should include users that have the brands assigned to' do
      brand = create(:brand, company_id: 1)
      campaign = create(:campaign, brand_ids: [brand.id], company_id: 1)

      # This is an user that is following all the campaigns of this brand
      user = create(:company_user, brand_ids: [brand.id], company_id: 1)

      # Create another user related to another brand
      create(:company_user, brand_ids: [create(:brand).id], company_id: 1)

      expect(campaign.staff_users).to eq([user])
    end

    it 'should include users that have the brand portfolios assigned to' do
      brand_portfolio = create(:brand_portfolio)
      campaign = create(:campaign, brand_portfolio_ids: [brand_portfolio.id], company_id: 1)

      # This is an user that is following all the campaigns of this brand
      user = create(:company_user, brand_portfolio_ids: [brand_portfolio.id], company_id: 1)

      # Create another user related to another brand portfolio
      create(:company_user, brand_portfolio_ids: [create(:brand_portfolio).id], company_id: 1)

      expect(campaign.staff_users).to eq([user])
    end

    it 'should include users that are directly assigned to the campaign' do
      campaign = create(:campaign, company_id: 1)

      # This is an user that is assgined to the campaign
      user = create(:company_user, company_id: 1)

      campaign.users << user

      expect(campaign.staff_users).to eq([user])
    end

    it 'mixup between the diferent sources' do
      brand_portfolio = create(:brand_portfolio)
      brand = create(:brand)
      brand2 = create(:brand)
      campaign = create(:campaign, brand_portfolio_ids: [brand_portfolio.id], brand_ids: [brand.id, brand2.id], company_id: 1)

      # This is an user that is following all the campaigns of this brand
      user = create(:company_user, brand_portfolio_ids: [brand_portfolio.id], brand_ids: [brand.id], company_id: 1)
      user2 = create(:company_user, brand_ids: [brand2.id], company_id: 1)

      # Create another user related to another brand portfolio
      create(:company_user, brand_portfolio_ids: [create(:brand_portfolio).id], company_id: 1)

      expect(campaign.staff_users).to match_array([user, user2])
    end
  end

  describe 'all_users_with_access' do
    let(:company) { create(:company) }
    let(:non_admin_role) { create(:non_admin_role, company: company) }
    it 'should include users that have the brands assigned to' do
      brand = create(:brand, company: company)
      campaign = create(:campaign, brand_ids: [brand.id], company: company)

      # This is an user that is following all the campaigns of this brand
      user = create(:company_user, brand_ids: [brand.id], company: company)

      # Create another user related to another brand
      create(:company_user,
                         brand_ids: [create(:brand, company: company).id],
                         role: non_admin_role, company: company)

      expect(campaign.all_users_with_access).to eq([user])
    end

    it 'should include users that have the brand portfolios assigned to' do
      brand_portfolio = create(:brand_portfolio, company: company)
      campaign = create(:campaign, brand_portfolio_ids: [brand_portfolio.id], company: company)

      # This is an user that is following all the campaigns of this brand
      user = create(:company_user, brand_portfolio_ids: [brand_portfolio.id], company: company)

      # Create another user related to another brand portfolio
      create(:company_user,
                         brand_portfolio_ids: [create(:brand_portfolio, company: company).id],
                         company: company, role: non_admin_role)

      expect(campaign.all_users_with_access).to eq([user])
    end

    it 'should include users that are directly assigned to the campaign' do
      campaign = create(:campaign, company: company)

      # This is an user that is assgined to the campaign
      user = create(:company_user, company: company)
      create(:company_user, company: company, role: non_admin_role)

      campaign.users << user

      expect(campaign.all_users_with_access).to eq([user])
    end

    it 'should include all admin users' do
      campaign = create(:campaign, company: company)

      # This is an user that is assgined to the campaign
      admin_user = create(:company_user, company: company)

      expect(campaign.all_users_with_access).to match_array [admin_user]
    end

    it 'should include users that belong to teams directly assigned to the campaign' do
      campaign = create(:campaign, company: company)

      # This is an user that is assgined to the campaign
      user = create(:company_user, company: company)
      team = create(:team, company: company)
      team.users << user

      campaign.teams << team

      expect(campaign.all_users_with_access).to eq([user])
    end

    it 'mixup between the diferent sources' do
      brand_portfolio = create(:brand_portfolio, company: company)
      brand = create(:brand, company: company)
      brand2 = create(:brand, company: company)
      campaign = create(:campaign, brand_portfolio_ids: [brand_portfolio.id], brand_ids: [brand.id, brand2.id], company: company)

      team = create(:team, company: company)
      not_assigned_team = create(:team, company: company)

      # This is an user that is following all the campaigns of this brand
      user = create(:company_user, brand_portfolio_ids: [brand_portfolio.id], brand_ids: [brand.id], company: company)
      user2 = create(:company_user, brand_ids: [brand2.id], company: company)

      not_assigned_user = create(:company_user, role: non_admin_role, company: company)

      team.users << user
      not_assigned_team.users << not_assigned_user

      # Create another user related to another brand portfolio
      create(:company_user,
                         brand_portfolio_ids: [create(:brand_portfolio, company: company).id],
                         role: non_admin_role, company: company)

      expect(campaign.all_users_with_access).to match_array([user, user2])
    end
  end

  describe 'place_allowed_for_event?' do
    let(:campaign) { create(:campaign) }

    it "should return true if the campaing doesn't have areas or places assigned" do
      place = create(:place)
      expect(campaign.place_allowed_for_event?(place)).to be_truthy
    end

    it 'should return true if the place have been assigned to the campaign directly' do
      place = create(:place)
      other_place = create(:place)
      campaign.places << other_place

      expect(campaign.place_allowed_for_event?(place)).to be_falsey

      campaign.places << place

      expect(campaign.reload.place_allowed_for_event?(place)).to be_truthy
    end

    it 'should return true if the place is part of any of the campaigns' do
      area = create(:area)
      place = create(:place, country: 'CR')
      other_place = create(:place, country: 'US')
      area.places << other_place
      campaign.areas << area

      expect(campaign.place_allowed_for_event?(place)).to be_falsey

      area.places << place

      expect(campaign.reload.place_allowed_for_event?(place)).to be_truthy
    end

    it 'should return true if the place is part of any city of an area associated to the campaign' do
      area =  create(:area)
      city =  create(:place, types: ['locality'], city: 'San Francisco', state: 'California', country: 'US')
      place = create(:place, types: ['establishment'], city: 'San Francisco', state: 'California', country: 'US')
      other_city = create(:place, types: ['locality'], city: 'Los Angeles', state: 'California', country: 'US')
      area.places << other_city
      campaign.areas << area

      expect(campaign.place_allowed_for_event?(place)).to be_falsey

      # Assign San Francisco to the area
      area.places << city

      # Because the campaing cache the locations, load a new object with the same campaign ID
      expect(Campaign.find(campaign.id).place_allowed_for_event?(place)).to be_truthy
    end

    it 'should work with places that are not yet saved' do
      area =  create(:area)
      city =  create(:place, types: ['locality'], city: 'San Francisco', state: 'California', country: 'US')
      place = build(:place, types: ['establishment'], city: 'San Francisco', state: 'California', country: 'US')
      campaign.areas << area

      # Assign San Francisco to the area
      area.places << city

      # Because the campaing cache the locations, load a new object with the same campaign ID
      expect(campaign.place_allowed_for_event?(place)).to be_truthy
    end
  end

  describe '#event_status_data_by_staff' do
    let(:company) { create(:company) }
    let(:campaign) { create(:campaign, company: company) }
    before(:each) { Kpi.create_global_kpis }

    it 'should return empty if the campaign has no users or teams associated' do
      stats = campaign.event_status_data_by_staff
      expect(stats).to be_empty
    end

    it 'should return empty if the campaign has users but none have goals' do
      area = create(:area, name: 'California', company: company)
      campaign.users << create(:company_user, company: company)
      stats = campaign.event_status_data_by_staff

      expect(stats).to be_empty
    end

    it 'should not include include only users with goals' do
      area = create(:area, name: 'California', company: company)
      user1 = create(:company_user, company: company)
      user2 = create(:company_user, company: company)
      campaign.users << [user1, user2]
      create(:goal, parent: campaign, goalable: user1, kpi: Kpi.promo_hours, value: 20)

      stats = campaign.event_status_data_by_staff

      expect(stats).to eql [{
        'id' => user1.id,
        'name' => user1.full_name,
        'goal' => 20,
        'kpi' => 'PROMO HOURS',
        'executed' => 0.0,
        'scheduled' => 0.0,
        'remaining' => 20,
        'executed_percentage' => 0,
        'scheduled_percentage' => 0,
        'remaining_percentage' => 100
      }]
    end

    it 'should count approved past events as executed' do
      area = create(:area, name: 'California', company: company)
      user = create(:company_user, company: company)
      campaign.users << user
      create(:goal, parent: campaign, goalable: user, kpi: Kpi.promo_hours, value: 20)

      # Should count events in the past as executed
      create(:approved_event, campaign: campaign, user_ids: [user.id],
          start_time: '08:00AM', end_time: '10:00AM', start_date: '01/23/2013', end_date: '01/23/2013')

      stats = campaign.event_status_data_by_staff

      expect(stats).to eql [{
        'id' => user.id,
        'name' => user.full_name,
        'goal' => 20,
        'kpi' => 'PROMO HOURS',
        'executed' => 2.0,
        'scheduled' => 0.0,
        'remaining' => 18,
        'executed_percentage' => 10,
        'scheduled_percentage' => 0,
        'remaining_percentage' => 90
      }]
    end

    it 'should count approved upcoming events as executed' do
      area = create(:area, name: 'California', company: company)
      user = create(:company_user, company: company)
      campaign.users << user
      create(:goal, parent: campaign, goalable: user, kpi: Kpi.promo_hours, value: 20)

      # Should count events in the past as executed
      create(:approved_event, campaign: campaign, user_ids: [user.id],
          start_time: '08:00AM', end_time: '10:00AM',
          start_date: 2.days.from_now.to_s(:slashes), end_date: 2.days.from_now.to_s(:slashes))

      stats = campaign.event_status_data_by_staff

      expect(stats).to eql [{
        'id' => user.id,
        'name' => user.full_name,
        'goal' => 20,
        'kpi' => 'PROMO HOURS',
        'executed' => 0.0,
        'scheduled' => 2.0,
        'remaining' => 18,
        'executed_percentage' => 0,
        'scheduled_percentage' => 10,
        'remaining_percentage' => 90
      }]
    end
  end

  describe '#event_status_data_by_areas' do
    let(:company) { create(:company) }
    let(:user) { create(:company_user, company: company) }
    let(:campaign) { create(:campaign, company: company) }
    before(:each) { Kpi.create_global_kpis }

    it 'should return empty if the campaign has no areas associated' do
      stats = campaign.event_status_data_by_areas(user)
      expect(stats).to be_empty
    end

    it 'should return empty if the campaign has areas but none have goals' do
      area = create(:area, name: 'California', company: company)
      campaign.areas << area
      stats = campaign.event_status_data_by_areas(user)

      expect(stats).to be_empty
    end

    it 'should return the results for all areas on the campaign with goals' do
      area = create(:area, name: 'California', company: company)
      other_area = create(:area, company: company)
      los_angeles = create(:place, city: 'Los Angeles', state: 'California', types: ['political'])
      area.places << los_angeles
      other_area.places << los_angeles
      campaign.areas << [area, other_area]
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.promo_hours, value: 20)
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.events, value: 10)
      create(:event, campaign: campaign, place: create(:place, city: 'Los Angeles', state: 'California'))
      stats = campaign.event_status_data_by_areas(user)
      expect(stats.count).to eql 2

      expect(stats.first['id']).to eql area.id
      expect(stats.first['name']).to eql 'California'
      expect(stats.first['kpi']).to eql 'EVENTS'
      expect(stats.first['goal']).to eql 10.0
      expect(stats.first['executed']).to eql 0.0
      expect(stats.first['scheduled']).to eql 1.0
      expect(stats.first['remaining']).to eql 9.0
      expect(stats.first['executed_percentage']).to eql 0
      expect(stats.first['scheduled_percentage']).to eql 10
      expect(stats.first['remaining_percentage']).to eql 90
      expect(stats.first.key?('today')).to be_falsey
      expect(stats.first.key?('today_percentage')).to be_falsey

      expect(stats.last['id']).to eql area.id
      expect(stats.last['name']).to eql 'California'
      expect(stats.last['kpi']).to eql 'PROMO HOURS'
      expect(stats.last['goal']).to eql 20.0
      expect(stats.last['executed']).to eql 0.0
      expect(stats.last['scheduled']).to eql 2.0
      expect(stats.last['remaining']).to eql 18.0
      expect(stats.last['executed_percentage']).to eql 0
      expect(stats.last['scheduled_percentage']).to eql 10
      expect(stats.last['remaining_percentage']).to eql 90
      expect(stats.last.key?('today')).to be_falsey
      expect(stats.last.key?('today_percentage')).to be_falsey

    end

    it 'should return the results for all areas on the campaign with goals even if there are not events' do
      area = create(:area, name: 'California', company: company)
      area.places << create(:place, city: 'Los Angeles', state: 'California', types: ['political'])
      campaign.areas << area
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.promo_hours, value: 10)
      stats = campaign.event_status_data_by_areas(user)
      expect(stats.count).to eql 1

      expect(stats.first['id']).to eql area.id
      expect(stats.first['name']).to eql 'California'
      expect(stats.first['kpi']).to eql 'PROMO HOURS'
      expect(stats.first['goal']).to eql 10.0
      expect(stats.first['executed']).to eql 0.0
      expect(stats.first['scheduled']).to eql 0.0
      expect(stats.first['remaining']).to eql 10.0
      expect(stats.first['executed_percentage']).to eql 0
      expect(stats.first['scheduled_percentage']).to eql 0
      expect(stats.first['remaining_percentage']).to eql 100
      expect(stats.first.key?('today')).to be_falsey
      expect(stats.first.key?('today_percentage')).to be_falsey
    end

    it 'should set the today values correctly' do
      area = create(:area, name: 'California', company: company)
      area.places << create(:place, city: 'Los Angeles', state: 'California', types: ['political'])
      campaign = create(:campaign, start_date: '01/01/2014', end_date: '02/01/2014', company: company)
      campaign.areas << area
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.promo_hours, value: 10)
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.events, value: 5)

      some_bar_in_los_angeles = create(:place, city: 'Los Angeles', state: 'California')
      event = create(:approved_event, start_time: '8:00pm', end_time: '11:00pm',
        campaign: campaign, place: some_bar_in_los_angeles)
      event = create(:event, start_time: '9:00pm', end_time: '10:00pm',
        campaign: campaign, place: some_bar_in_los_angeles)
      event = create(:event, start_time: '9:00pm', end_time: '10:00pm',
        campaign: campaign, place: some_bar_in_los_angeles)
      event = create(:event, start_time: '9:00pm', end_time: '10:00pm',
        campaign: campaign, place: some_bar_in_los_angeles)

      Timecop.travel Date.new(2014, 01, 15) do
        all_stats = campaign.event_status_data_by_areas(user)
        expect(all_stats.count).to eql 2
        stats = all_stats.find { |r| r['kpi'] == 'PROMO HOURS' }
        expect(stats['today'].to_s).to eql '4.838709677419354839'
        expect(stats['today_percentage']).to eql 48

        stats = all_stats.find { |r| r['kpi'] == 'EVENTS' }
        expect(stats['kpi']).to eql 'EVENTS'
        expect(stats['today'].to_s).to eql '2.419354838709677419'
        expect(stats['today_percentage']).to eql 48
      end

      Timecop.travel Date.new(2014, 01, 25) do
        all_stats = campaign.event_status_data_by_areas(user)
        expect(all_stats.count).to eql 2

        stats = all_stats.find { |r| r['kpi'] == 'PROMO HOURS' }
        expect(stats['today'].to_s).to eql '8.064516129032258065'
        expect(stats['today_percentage']).to eql 80

        stats = all_stats.find { |r| r['kpi'] == 'EVENTS' }
        expect(stats['today'].to_s).to eql '4.032258064516129032'
        expect(stats['today_percentage']).to eql 80
      end

      # When the campaing end date is before the current date
      Timecop.travel Date.new(2014, 02, 25) do
        all_stats = campaign.event_status_data_by_areas(user)
        expect(all_stats.count).to eql 2

        stats = all_stats.find { |r| r['kpi'] == 'PROMO HOURS' }
        expect(stats['today']).to eql 10.0
        expect(stats['today_percentage']).to eql 100

        stats = all_stats.find { |r| r['kpi'] == 'EVENTS' }
        expect(stats['today']).to eql 5.0
        expect(stats['today_percentage']).to eql 100
      end

      # When the campaing start date is after the current date
      Timecop.travel Date.new(2013, 12, 25) do
        all_stats = campaign.event_status_data_by_areas(user)
        expect(all_stats.count).to eql 2

        stats = all_stats.find { |r| r['kpi'] == 'PROMO HOURS' }
        expect(stats['today']).to eql 0
        expect(stats['today_percentage']).to eql 0

        stats = all_stats.find { |r| r['kpi'] == 'EVENTS' }
        expect(stats['today']).to eql 0
        expect(stats['today_percentage']).to eql 0
      end
    end
  end

  describe 'self.promo_hours_graph_data' do
    before(:each) do
      Kpi.create_global_kpis
    end
    it 'should return empty when there are no campaigns and events' do
      stats = Campaign.promo_hours_graph_data
      expect(stats).to be_empty
    end

    it 'should return empty when there are campaigns but no goals' do
      create(:campaign)
      stats = Campaign.promo_hours_graph_data
      expect(stats).to be_empty
    end

    it 'should the stats for events kpi if the campaign has goals' do
      campaign = create(:campaign, name: 'TestCmp1')
      campaign.goals.for_kpi(Kpi.events).value = 10
      campaign.save

      create(:approved_event, start_date: '01/23/2013', end_date: '01/23/2013', campaign: campaign)

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

    it 'should the stats for promo_hours kpi if the campaign has goals' do
      campaign = create(:campaign, name: 'TestCmp1')
      campaign.goals.for_kpi(Kpi.promo_hours).value = 10
      campaign.save

      create(:approved_event, start_date: '01/23/2013', end_date: '01/23/2013', start_time: '8:00pm', end_time: '11:00pm', campaign: campaign)

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

    it 'should the stats for promo_hours and events kpi if the campaign has goals for both kpis' do
      campaign = create(:campaign, name: 'TestCmp1')
      campaign.goals.for_kpi(Kpi.promo_hours).value = 10
      campaign.goals.for_kpi(Kpi.events).value = 5
      campaign.save

      create(:approved_event, start_date: '01/23/2013', end_date: '01/23/2013', start_time: '8:00pm', end_time: '11:00pm', campaign: campaign)

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

    it 'should count rejected, new and submitted events as scheduled' do
      campaign = create(:campaign, name: 'TestCmp1')
      campaign.goals.for_kpi(Kpi.promo_hours).value = 10
      campaign.goals.for_kpi(Kpi.events).value = 5
      campaign.save

      create(:approved_event, start_date: '01/23/2013', end_date: '01/23/2013', start_time: '8:00pm', end_time: '11:00pm', campaign: campaign)
      create(:rejected_event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)
      create(:submitted_event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)
      create(:event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)

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

    it 'should set the today values correctly' do
      campaign = create(:campaign, name: 'TestCmp1', start_date: '01/01/2014', end_date: '02/01/2014')
      campaign.goals.for_kpi(Kpi.promo_hours).value = 10
      campaign.goals.for_kpi(Kpi.events).value = 5
      campaign.save

      create(:approved_event, start_time: '8:00pm', end_time: '11:00pm', campaign: campaign)
      create(:event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)
      create(:event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)
      create(:event, start_time: '9:00pm', end_time: '10:00pm', campaign: campaign)

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

  describe '#in_date_range?' do
    it 'returns true if both dates are inside the start/end dates' do
      campaign = build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2014, 1, 3), Date.new(2014, 1, 23))).to be_truthy
    end

    it 'returns true if start date is inside the start/end dates' do
      campaign = build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2014, 1, 3), Date.new(2014, 6, 23))).to be_truthy
    end

    it 'returns true if end date is inside the start/end dates' do
      campaign = build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2013, 1, 3), Date.new(2014, 1, 23))).to be_truthy
    end

    it 'returns false if both dates are after the end date' do
      campaign = build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2014, 3, 3), Date.new(2014, 3, 23))).to be_falsey
    end

    it 'returns false if both dates are before the start date' do
      campaign = build(:campaign, start_date: '01/01/2014', end_date: '02/01/2014')
      expect(campaign.in_date_range?(Date.new(2013, 1, 3), Date.new(2013, 2, 23))).to be_falsey
    end
  end

end
