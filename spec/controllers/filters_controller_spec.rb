require 'rails_helper'

RSpec.describe FiltersController, type: :controller do

  let(:company) { create(:company) }
  let(:user) { company_user.user }
  let(:role) { create(:role, is_admin: false, company: company) }
  let(:company_user) { create(:company_user, company: company, role: role) }

  before { sign_in user }

  describe 'GET show' do

    describe 'Events' do
      describe 'as admin user' do
        let(:role) { create(:role, company: company) }

        it 'not return objects for other companies' do
          create(:campaign, name: 'CFY12', company: company)
          create(:campaign, name: 'IN OTHER COMPANY', company: create(:company))
          get 'show', id: :events, format: :json

          filters = json['filters'].find { |f| f['label'] == 'Campaigns' }

          expect(filters['items'].map { |i| i['label'] }).to eql ['CFY12']
        end
      end

      it 'returns all the keys for the events scope' do
        get :show, id: 'events'
        expect(response).to be_success
        expect(json['filters'].map { |b| b['label'] }).to eq([
          'Campaigns', 'Brands', 'Areas', 'People', 'Event Status',
          'Active State', 'Saved Filters'])
      end

      it 'should return the correct items for the Campaign bucket' do
        # Assigned area with a common place, it should be in the filters
        campaign = create(:campaign, name: 'CFY12', company: company)

        # Not assigned campaign
        create(:campaign, company: company)

        # Inactive campaign
        inactive_campaign = create(:campaign, company: company, aasm_state: 'inactive')

        # Campaign in another company
        create(:campaign, company: create(:company))

        company_user.campaigns << [campaign, inactive_campaign]

        get 'show', id: :events, format: :json
        expect(response).to be_success
        filters = json['filters'].find { |f| f['label'] == 'Campaigns' }
        expect(filters['items'].count).to eql 1

        expect(filters['items'].first).to eql(
          'id' => campaign.id, 'label' => 'CFY12', 'value' => campaign.id,
          'name' => 'campaign', 'selected' => false
        )
      end

      it 'should return active state bucket' do
        # Assigned area with a common place, it should be in the filters
        campaign = create(:campaign, name: 'CFY12', company: company)

        # Not assigned campaign
        create(:campaign, company: company)

        # Inactive campaign
        inactive_campaign = create(:campaign, company: company, aasm_state: 'inactive')

        # Campaign in another company
        create(:campaign, company: create(:company))

        company_user.campaigns << [campaign, inactive_campaign]

        get 'show', id: :events, format: :json
        expect(response).to be_success
        areas_filters = json['filters'].find { |f| f['label'] == 'Active State' }
        expect(areas_filters['items'].count).to eql 2

        expect(areas_filters['items'].first).to eql(
          'id' => 'Active', 'label' => 'Active', 'value' => 'Active',
          'name' => 'status', 'selected' => false
        )
      end

      it 'should return the correct items for the Area bucket' do
        # Assigned area with a common place, it should be in the filters
        area = create(:area, name: 'Austin', company: company)
        area.places << create(:city, name: 'Bee Cave', state: 'Texas', country: 'US')
        company_user.areas << area

        # Unassigned area with a common place, it should be in the filters
        area_unassigned = create(:area, name: 'San Antonio', company: company)
        area_unassigned.places << create(:city, name: 'Schertz',
                                                state: 'Texas', country: 'US')

        # Unassigned area with not common place, it should not be in the filters
        area_not_in_filter = create(:area, name: 'Miami', company: company)
        area_not_in_filter.places << create(:city, name: 'Doral',
                                                   state: 'Florida', country: 'US')

        # Assigned area with not common place, it should be in the filters
        company_user.areas << create(:area, name: 'San Francisco', company: company)

        # Assigned place, itis the responsible for the common areas in the filters
        company_user.places << create(:state, name: 'Texas', country: 'US')

        get 'show', id: :events, format: :json
        expect(response).to be_success
        areas_filters = json['filters'].find { |f| f['label'] == 'Areas' }
        expect(areas_filters['items'].count).to eql 3

        expect(areas_filters['items'].first).to eql(
          'id' => area.id, 'label' => 'Austin', 'value' => area.id,
          'name' => 'area', 'selected' => false
        )

        expect(areas_filters['items'].map { |i| i['label'] }).to eql [
          'Austin', 'San Antonio', 'San Francisco']
      end
    end
  end

  describe 'Activity Types' do
    it 'should return the correct filters in the right order' do
      Sunspot.commit
      get 'show', id: :activity_types, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Active State', 'Saved Filters'])
    end
  end

  describe 'Brand Portfolios' do
    it 'should return the correct filters in the right order' do
      get 'show', id: :brand_portfolios, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Brands', 'Active State', 'Saved Filters'])
    end
  end

  describe "Brands'" do
    it 'should return the correct filters in the right order' do
      get 'show', id: :brands, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Active State', 'Saved Filters'])
    end
  end

  describe 'Campaigns' do
    it 'should return the correct filters in the right order' do
      get 'show', id: :campaigns, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Brands', 'Brand Portfolios', 'People', 'Active State', 'Saved Filters'])
    end
  end

  describe 'Company Users' do
    it 'should return the correct filters in the right order' do
      get 'show', id: :company_users, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Roles', 'Campaigns', 'Teams', 'Active State', 'Saved Filters'])
    end
  end

  describe 'Day Parts' do
    it 'should return the correct filters in the right order' do
      get 'show', id: :day_parts, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Active State', 'Saved Filters'])
    end
  end

  describe 'Brand Portfolios' do
    it 'should return the correct filters in the right order' do
      get 'show', id: :brand_portfolios, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Brands', 'Active State', 'Saved Filters'])
    end
  end

  describe 'Brand Portfolios' do
    it 'should return the correct filters in the right order' do
      get 'show', id: :brands, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Active State', 'Saved Filters'])
    end
  end

  describe 'Roles' do
    it 'should return the correct filters in the right order' do
      get 'show', id: :roles, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Active State', 'Saved Filters'])
    end
  end

  describe 'Tasks' do
    it 'should return the correct buckets in the right order for user tasks' do
      get 'show', id: :user_tasks, format: :json, scope: 'user'
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Campaigns', 'Task Status', 'Active State', 'Saved Filters'])
    end

    it 'should return the correct buckets in the right order teams tasks' do
      get 'show', id: :teams_tasks, format: :json, scope: 'teams'
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Campaigns', 'Task Status', 'Staff', 'Active State', 'Saved Filters'])
    end
  end

  describe 'Venues', search: true do
    it 'should return the correct buckets in the right order' do
      get 'show', id: :venues, format: :json
      expect(response).to be_success

      # TODO: make this test to return the ranges filters as well

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Events', 'Impressions', 'Interactions', 'Promo Hours', 'Samples', 'Venue Score',
        '$ Spent', 'Price', 'Areas', 'Campaigns', 'Brands', 'Saved Filters'])
    end
  end

  describe 'photos' do
    it 'returns the correct buckets' do
      get 'show', id: :results_photos, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Campaigns', 'Brands', 'Areas', 'Tags', 'Star Rating', 'Active State', 'Saved Filters'])
    end
  end

  describe 'Results/Activities' do
    it 'should return the correct filters in the right order' do
      get 'show', id: 'activities', format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Activity Types', 'Brands', 'Campaigns', 'Areas', 'Users',
        'Active State', 'Saved Filters'])
    end
  end

  describe 'Brand Ambassadors Visits' do
    it 'should return the correct buckets in the right order' do
      custom_filters_category = create(:custom_filters_category, name: 'DIVISIONS', company: company)
      create(:custom_filter, owner: company, category: custom_filters_category, apply_to: 'visits')

      get 'show', id: 'visits', format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'DIVISIONS', 'Brand Ambassadors', 'Campaigns', 'Areas', 'Cities', 'Saved Filters'])
    end

    it 'should return only users in the configured role for brand ambassadors section' do
      role = create(:role, company: company)
      user = create(:company_user, company: company,
        user: create(:user, first_name: 'Julio', last_name: 'Cesar'), role: role)
      company.brand_ambassadors_role_ids = [role.id]
      company.save

      get 'show', id: 'visits', format: :json
      expect(response).to be_success

      expect(json['filters'].find { |b| b['label'] == 'Brand Ambassadors' }['items']).to eq([
        {
          'label' => 'Julio Cesar',
          'id' => user.id,
          'name' => 'user',
          'selected' => false
        }
      ])
    end

    it 'should return the correct items for the Area bucket' do
      company_user.role.permission_for(:view_list, Event).save

      # Assigned area with a common place, it should be in the filters
      area = create(:area, name: 'Austin', company: company)
      area.places << create(:place, name: 'Bee Cave', city: 'Bee Cave', state: 'Texas', country: 'US', types: %w(locality political))
      company_user.areas << area

      # Unassigned area with a common place, it should be in the filters
      area_unassigned = create(:area, name: 'San Antonio', company: company)
      area_unassigned.places << create(:place, name: 'Schertz', types: %w(locality political), city: 'Schertz', state: 'Texas', country: 'US')

      # Unassigned area with not common place, it should not be in the filters
      area_not_in_filter = create(:area, name: 'Miami', company: company)
      area_not_in_filter.places << create(:place, name: 'Doral', types: %w(locality political), city: 'Doral', state: 'Florida', country: 'US')

      # Assigned area with not common place, it should be in the filters
      company_user.areas << create(:area, name: 'San Francisco', company: company)

      # Assigned place, itis the responsible for the common areas in the filters
      company_user.places << create(:place, name: 'Texas', types: %w(administrative_area_level_1 political), city: nil, state: 'Texas', country: 'US')

      get 'show', id: 'visits', format: :json
      expect(response).to be_success

      areas_filters = json['filters'].find { |f| f['label'] == 'Areas' }
      expect(areas_filters['items'].count).to eql 3

      expect(areas_filters['items'].first['label']).to eql 'Austin'
      expect(areas_filters['items'].second['label']).to eql 'San Antonio'
      expect(areas_filters['items'].third['label']).to eql 'San Francisco'
    end

    describe 'when a user only a place assiged to it' do
      it 'returns all the areas that have at least one place inside' do
        company_user.role.permission_for(:view_list, Event).save

        # This is one area that have one place inside US
        area = create(:area, name: 'Austin', company: company)
        area.places << create(:place, name: 'Bee Cave',
              city: 'Bee Cave', state: 'Texas',
              country: 'US', types: %w(locality political))

        # This is another area that have one place inside US
        area = create(:area, name: 'San Antonio', company: company)
        area.places << create(:place, name: 'Schertz',
              types: %w(locality political), city: 'Schertz', state: 'Texas', country: 'US')

        # This area doesn't  have one place in US
        area = create(:area, name: 'Centro America', company: company)
        area.places << create(:place, name: 'Costa Rica',
              types: %w(country political), city: 'Schertz', state: nil, country: 'CR')

        # The user have US as the allowed places
        company_user.places << create(:place,
                                      name: 'United States', types: %w(country political),
                                      city: nil, state: nil, country: 'US')

        get 'show', id: 'visits', format: :json
        expect(response).to be_success

        # It should return the first two areas
        areas_filters = json['filters'].find { |f| f['label'] == 'Areas' }
        expect(areas_filters['items'].count).to eql 2
        expect(areas_filters['items'].first['label']).to eql 'Austin'
        expect(areas_filters['items'].second['label']).to eql 'San Antonio'
      end
    end
  end

  describe 'Analysis / Trends' do
    it 'returns the correct buckets' do
      get 'show', id: :trends, format: :json
      expect(response).to be_success

      expect(json['filters'].map { |b| b['label'] }).to eq([
        'Source', 'Questions', 'Campaigns', 'Brands', 'Areas', 'Saved Filters'])
    end
  end
end
