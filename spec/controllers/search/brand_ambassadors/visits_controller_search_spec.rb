require 'rails_helper'

describe BrandAmbassadors::VisitsController, type: :controller, search: true do
  describe 'As Super User' do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.companies.first
      @company_user = @user.current_company_user
    end

    let(:campaign) { create(:campaign, company: @company) }

    it 'returns the list of visits' do
      visit = create(:brand_ambassadors_visit,
                                 visit_type: 'market_visit', start_date: '08/26/2014', end_date: '08/27/2014',
                                 company: @company, campaign: campaign, active: true)
      Sunspot.commit
      get 'index', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to eql [
        { 'visit_type_name' => 'Market Visit',
          'campaign_name' => campaign.name, 'city' => visit.city,
          'start' => '2014-08-26', 'end' => '2014-08-27T23:59:59.999-07:00',
          'url' => "http://test.host/brand_ambassadors/visits/#{visit.id}",
          'company_user' => { 'full_name' => @user.full_name } }
      ]
    end

    describe "GET 'autocomplete'" do
      it 'should return the correct buckets in the right order' do
        Sunspot.commit
        get 'autocomplete'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        expect(buckets.map { |b| b['label'] }).to eq(%w(Brands Places People))
      end

      it 'should return the users in the People Bucket' do
        user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'gu'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select { |b| b['label'] == 'People' }.first
        expect(people_bucket['value']).to eq([{ 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s, 'type' => 'company_user' }])
      end

      it 'should return users only in the People Bucket' do
        team = create(:team, name: 'Valladolid', company_id: @company.id)
        user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
        company_user = user.company_users.first
        Sunspot.commit

        get 'autocomplete', q: 'va'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        people_bucket = buckets.select { |b| b['label'] == 'People' }.first
        expect(people_bucket['value']).to eq([{ 'label' => 'Guillermo <i>Va</i>rgas', 'value' => company_user.id.to_s, 'type' => 'company_user' }])
      end

      it 'should return the brands in the Brands Bucket' do
        brand = create(:brand, name: 'Cacique', company_id: @company.id)
        Sunspot.commit

        get 'autocomplete', q: 'cac'
        expect(response).to be_success

        buckets = JSON.parse(response.body)
        brands_bucket = buckets.select { |b| b['label'] == 'Brands' }.first
        expect(brands_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
      end
    end

    describe "GET 'filters'" do
      it 'should return the correct buckets in the right order' do
        create(:custom_filter, owner: @company_user, group: 'DIVISIONS', apply_to: 'visits')
        Sunspot.commit
        get 'filters', format: :json
        expect(response).to be_success

        filters = JSON.parse(response.body)
        expect(filters['filters'].map { |b| b['label'] }).to eq(['DIVISIONS', 'Brand Ambassadors', 'Areas', 'Cities', 'Brands'])
      end

      it 'should return only users in the configured role for brand ambassadors section' do
        role = create(:role, company: @company)
        user = create(:company_user, company: @company,
          user: create(:user, first_name: 'Julio', last_name: 'Cesar'), role: role)
        @company.brand_ambassadors_role_ids = [role.id]
        @company.save
        Sunspot.commit
        get 'filters', format: :json
        expect(response).to be_success

        filters = JSON.parse(response.body)
        expect(filters['filters'].find { |b| b['label'] == 'Brand Ambassadors' }['items']).to eq([{
                                                                                                   'label' => 'Julio Cesar',
                                                                                                   'id' => user.id,
                                                                                                   'name' => 'user',
                                                                                                   'count' => 1,
                                                                                                   'selected' => false }
                                                                                                 ])
      end
    end
  end

  describe 'As NOT Super User' do
    before(:each) do
      @company = create(:company)
      @company_user = create(:company_user,
                                         company: @company,
                                         role: create(:role, is_admin: false, company: @company))
      @user = @company_user.user
      sign_in @user
    end

    describe "GET 'filters'" do
      it 'should return the correct items for the Area bucket' do
        @company_user.role.permission_for(:view_list, Event).save

        # Assigned area with a common place, it should be in the filters
        area = create(:area, name: 'Austin', company: @company)
        area.places << create(:place, name: 'Bee Cave', city: 'Bee Cave', state: 'Texas', country: 'US', types: %w(locality political))
        @company_user.areas << area

        # Unassigned area with a common place, it should be in the filters
        area_unassigned = create(:area, name: 'San Antonio', company: @company)
        area_unassigned.places << create(:place, name: 'Schertz', types: %w(locality political), city: 'Schertz', state: 'Texas', country: 'US')

        # Unassigned area with not common place, it should not be in the filters
        area_not_in_filter = create(:area, name: 'Miami', company: @company)
        area_not_in_filter.places << create(:place, name: 'Doral', types: %w(locality political), city: 'Doral', state: 'Florida', country: 'US')

        # Assigned area with not common place, it should be in the filters
        @company_user.areas << create(:area, name: 'San Francisco', company: @company)

        # Assigned place, itis the responsible for the common areas in the filters
        @company_user.places << create(:place, name: 'Texas', types: %w(administrative_area_level_1 political), city: nil, state: 'Texas', country: 'US')

        get 'filters', format: :json
        expect(response).to be_success

        filters = JSON.parse(response.body)
        areas_filters = filters['filters'].find { |f| f['label'] == 'Areas' }
        expect(areas_filters['items'].count).to eql 3

        expect(areas_filters['items'].first['label']).to eql 'Austin'
        expect(areas_filters['items'].second['label']).to eql 'San Antonio'
        expect(areas_filters['items'].third['label']).to eql 'San Francisco'
      end

      describe 'when a user only a place assiged to it' do
        it 'returns all the areas that have at least one place inside' do
          @company_user.role.permission_for(:view_list, Event).save

          # This is one area that have one place inside US
          area = create(:area, name: 'Austin', company: @company)
          area.places << create(:place, name: 'Bee Cave',
                city: 'Bee Cave', state: 'Texas',
                country: 'US', types: %w(locality political))

          # This is another area that have one place inside US
          area = create(:area, name: 'San Antonio', company: @company)
          area.places << create(:place, name: 'Schertz',
                types: %w(locality political), city: 'Schertz', state: 'Texas', country: 'US')

          # This area doesn't  have one place in US
          area = create(:area, name: 'Centro America', company: @company)
          area.places << create(:place, name: 'Costa Rica',
                types: %w(country political), city: 'Schertz', state: nil, country: 'CR')

          # The user have US as the allowed places
          @company_user.places << create(:place,
                                                     name: 'United States', types: %w(country political),
                                                     city: nil, state: nil, country: 'US')

          get 'filters', format: :json
          expect(response).to be_success

          filters = JSON.parse(response.body)

          # It should return the first two areas
          areas_filters = filters['filters'].find { |f| f['label'] == 'Areas' }
          expect(areas_filters['items'].count).to eql 2
          expect(areas_filters['items'].first['label']).to eql 'Austin'
          expect(areas_filters['items'].second['label']).to eql 'San Antonio'
        end
      end
    end
  end

end
