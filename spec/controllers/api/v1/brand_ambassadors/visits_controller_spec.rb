require 'rails_helper'

describe Api::V1::BrandAmbassadors::VisitsController, type: :controller do
  let(:company) { user.company_users.first.company }
  let(:user) { sign_in_as_user }
  let(:company_user) { user.company_users.first }
  let(:campaign) { create(:campaign, name: 'My Campaign', company: company) }
  let(:area) { create(:area, name: 'My Area', company: company) }
  let(:today) { Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00) }

  before { set_api_authentication_headers user, company }

  describe "GET 'index'", search: true do
    it 'return a list of visits' do
      campaign = create(:campaign, company: company)
      create_list(:brand_ambassadors_visit, 3, company: company, campaign: campaign)
      Sunspot.commit

      get :index, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(3)
      expect(result['total']).to eq(3)
      expect(result['page']).to eq(1)
      expect(result['results'].first.keys).to match_array(%w(
        id visit_type visit_type_name start_date end_date campaign_id area_id
        city description status user campaign area))
    end

    it 'sencond page returns empty results' do
      campaign = create(:campaign, company: company)
      create_list(:brand_ambassadors_visit, 3, company: company, campaign: campaign)
      Sunspot.commit

      get :index, page: 2, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(0)
      expect(result['total']).to eq(3)
      expect(result['page']).to eq(2)
      expect(result['results']).to be_empty
    end

    it 'return a list of visits filtered by brand ambrassador id' do
      role = create(:role, company: company)
      other_user = create(:company_user, company: company, user: create(:user), role: role)
      create_list(:brand_ambassadors_visit, 3, company: company, company_user: company_user)
      create_list(:brand_ambassadors_visit, 3, company: company, company_user: other_user)
      company.brand_ambassadors_role_ids = [role.id]
      company.save
      Sunspot.commit

      get :index, user: [other_user.id], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(3)
    end

    it 'return a list of visits filtered by campaign id' do
      campaign = create(:campaign, company: company)
      other_campaign = create(:campaign, company: company)
      create_list(:brand_ambassadors_visit, 3, company: company, campaign: campaign)
      create_list(:brand_ambassadors_visit, 3, company: company, campaign: other_campaign)
      Sunspot.commit

      get :index, campaign: [campaign.id], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(3)
    end

    it 'return a list of visits filtered by area id' do
      other_area = create(:area, company: company)
      create_list(:brand_ambassadors_visit, 2, company: company, area: area)
      create_list(:brand_ambassadors_visit, 2, company: company, area: other_area)
      Sunspot.commit

      get :index, area: [area.id], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(2)
    end

    it 'return a list of visits filtered by city id' do
      city = create(:place, name: 'Bee Cave', city: 'Bee Cave', state: 'Texas', country: 'US', types: %w(locality political))
      create_list(:brand_ambassadors_visit, 4, company: company, city: 'New York')
      create_list(:brand_ambassadors_visit, 4, company: company, city: city.name)
      Sunspot.commit

      get :index, city: [city.name], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(4)
    end

    it 'return the facets for the search' do
      create(:brand_ambassadors_visit, company: company,
             start_date: today, end_date: (today + 1.day).to_s(:slashes),
             city: 'New York', area: area, campaign: campaign,
             visit_type: 'market_visit', company_user: company_user,
             description: 'The first visit description', active: true)
      create(:brand_ambassadors_visit, company: company,
             start_date: (today + 2.days).to_s(:slashes), end_date: (today + 3.days).to_s(:slashes),
             city: 'New York', area: area, campaign: campaign,
             visit_type: 'brand_program', company_user: company_user, active: true)

      # Make sure custom filters are not returned
      create(:custom_filter, owner: company, apply_to: 'visits')

      # Create the Divisions filter
      custom_filters_category = create(:custom_filters_category, name: 'DIVISIONS', company: company)
      create(:custom_filter, owner: company_user, category: custom_filters_category, apply_to: 'visits')

      Sunspot.commit

      get :index, format: :json
      expect(response).to be_success
      expect(json['results'].count).to eq(2)
      expect(json['facets'].map { |f| f['label'] }).to match_array([
        'DIVISIONS', 'Brand Ambassadors', 'Campaigns', 'Areas', 'Cities', 'Saved Filters'])
    end

    it 'should not include the facets when the page is greater than 1' do
      get :index, page: 2, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result['results']).to eq([])
      expect(result['facets']).to be_nil
      expect(result['page']).to eq(2)
    end
  end

  describe "GET 'show'" do
    let(:visit) { create(:brand_ambassadors_visit, company: company) }

    it 'returns http success' do
      get 'show', id: visit.to_param, format: :json
      expect(response).to be_success
      expect(response).to render_template('show')
    end
  end

  describe "PUT 'update'" do
    let(:campaign) { create(:campaign, company: company) }
    let(:visit) { create(:brand_ambassadors_visit, company: company) }
    it 'must update the visit attributes' do
      new_campaign = create(:campaign, company: company)
      area = create(:area, company: company)
      put 'update', id: visit.to_param, visit: {
        campaign_id: new_campaign.id,
        start_date: '05/21/2020', end_date: '05/22/2020',
        area_id: area.id, description: 'this is the test description'
      }, format: :json
      expect(assigns(:visit)).to eq(visit)
      expect(response).to be_success
      visit.reload
      expect(visit.campaign_id).to eq(new_campaign.id)
      expect(visit.start_date).to eq(Time.zone.parse('2020-05-21').to_date)
      expect(visit.end_date).to eq(Time.zone.parse('2020-05-22').to_date)
      expect(visit.area_id).to eq(area.id)
      expect(visit.description).to eq('this is the test description')
    end

    it 'must deactivate the visit' do
      put 'update', id: visit.to_param, visit: { active: 'false' }, format: :json
      expect(assigns(:visit)).to eq(visit)
      expect(response).to be_success
      visit.reload
      expect(visit.active).to eq(false)
    end

    it 'must update the visit attributes' do
      place = create(:place)
      put 'update', id: visit.to_param, partial: 'visit_data',
                    visit: { campaign_id: create(:campaign, company: company).to_param,
                             start_date: '05/21/2020', start_time: '12:00pm', end_date: '05/22/2020',
                             end_time: '01:00pm', place_id: place.id }, format: :json
      expect(assigns(:visit)).to eq(visit)
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it 'create a new visit' do
      expect do
        post 'create', visit: { start_date: '11/09/2014', end_date: '11/10/2014',
                                company_user_id: company_user.id, campaign_id: campaign.id,
                                area_id: area.id, city: 'Atlanta', visit_type: 'market_visit',
                                description: 'My new visit' }, format: :json
      end.to change(BrandAmbassadors::Visit, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('show')
      visit = BrandAmbassadors::Visit.last
      expect(visit.start_date).to eql Date.new(2014, 11, 9)
      expect(visit.end_date).to eql Date.new(2014, 11, 10)
      expect(visit.company_user_id).to eq(company_user.id)
      expect(visit.campaign_id).to eq(campaign.id)
      expect(visit.area_id).to eq(area.id)
      expect(visit.city).to eq('Atlanta')
      expect(visit.visit_type).to eq('market_visit')
      expect(visit.description).to eq('My new visit')
    end
  end

  describe '#events', search: true do
    it 'returns a list of events' do
      place1 = create(:place, name: 'Place 1', formatted_address: 'Los Angeles, CA, US', city: 'Los Angeles',
                      state: 'CA', country: 'US', zipcode: '90210', types: %w(political locality))
      place2 = create(:place, name: 'Place 2', formatted_address: 'Austin, TX, US', city: 'Austin',
                      state: 'TX', country: 'US', zipcode: '15879', types: %w(political locality))
      visit = create(:brand_ambassadors_visit, company: company,
                     start_date: '11/09/2014', end_date: '11/11/2014',
                     city: 'New York', area: area, campaign: campaign,
                     visit_type: 'market_visit', company_user: company_user,
                     description: 'The first visit description', active: true)

      event1 = create(:event, start_date: '11/09/2014', end_date: '11/09/2014', start_time: '10:00am', user_ids: [company_user.id],
                      end_time: '11:00am', campaign: campaign, place: place1, company: company, visit_id: visit.id)
      event2 = create(:event, start_date: '11/10/2014', end_date: '11/11/2014', start_time: '8:00am', user_ids: [company_user.id],
                      end_time: '9:00am', campaign: campaign, place: place2, company: company, visit_id: visit.id)

      Sunspot.commit

      get 'events', id: visit.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result).to match_array([
        { 'id' => event1.id, 'start_date' => '11/09/2014', 'start_time' => '10:00 AM',
           'end_date' => '11/09/2014', 'end_time' => '11:00 AM',
           'status' => 'Active', 'event_status' => 'Late',
           'campaign' => { 'id' => campaign.id, 'name' => 'My Campaign' },
           'place' => { 'id' => place1.id, 'name' => 'Place 1', 'formatted_address' => 'Los Angeles, CA, US',
                        'country' => 'US', 'state_name' => 'CA', 'city' => 'Los Angeles', 'zipcode' => '90210' } },
        { 'id' => event2.id, 'start_date' => '11/10/2014', 'start_time' => '8:00 AM',
          'end_date' => '11/11/2014', 'end_time' => '9:00 AM',
          'status' => 'Active', 'event_status' => 'Late',
          'campaign' => { 'id' => campaign.id, 'name' => 'My Campaign' },
          'place' => { 'id' => place2.id, 'name' => 'Place 2', 'formatted_address' => 'Austin, TX, US',
                       'country' => 'US', 'state_name' => 'TX', 'city' => 'Austin', 'zipcode' => '15879' } }])
    end
  end
end
