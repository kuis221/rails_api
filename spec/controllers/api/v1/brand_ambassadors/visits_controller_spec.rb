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
      expect(result['results'].first.keys).to match_array(%w(id visit_type_name start_date end_date campaign_name area_name city description status user))
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
      other_area = create(:area, company: company)
      other_area.places << create(:place, name: 'Bee Cave', city: 'Bee Cave', state: 'Texas', country: 'US', types: %w(locality political))
      create_list(:brand_ambassadors_visit, 4, company: company, area: area)
      create_list(:brand_ambassadors_visit, 4, company: company, area: other_area)
      Sunspot.commit

      get :index, area: [other_area.places.first.id], format: :json
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
      create(:custom_filter, owner: company, group: 'SAVED FILTERS', apply_to: 'visits')

      # Create the Divisions filter
      create(:custom_filter, owner: company_user, group: 'DIVISIONS', apply_to: 'visits')

      Sunspot.commit

      get :index, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(2)
      expect(result['facets'].map { |f| f['label'] }).to match_array(['DIVISIONS', 'Brand Ambassadors',
                                                                      'Campaigns', 'Areas', 'Cities',
                                                                      'SAVED FILTERS'])
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
end
