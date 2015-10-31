require 'rails_helper'

describe Api::V1::VenuesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  before { set_api_authentication_headers user, company }

  describe "GET 'index'", search: true do
    it 'return a list of venues', strategy: :deletion do
      campaign = create(:campaign, company: company)
      place1 = create(:place)
      place2 = create(:place)
      place3 = create(:place)
      create(:event, company: company, campaign: campaign, place: place1)
      create(:event, company: company, campaign: campaign, place: place2)
      create(:event, company: company, campaign: campaign, place: place3)
      Sunspot.commit

      get :index, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 3
      expect(result['total']).to eql 3
      expect(result['page']).to eql 1
      expect(result['results'].first.keys).to match_array %w(
        avg_impressions avg_impressions_cost avg_impressions_hour city country events_count
        formatted_address id impressions interactions latitude longitude name promo_hours
        sampled score spent state zipcode td_linx_code)
    end

    it 'second page should return no results', strategy: :deletion do
      campaign = create(:campaign, company: company)
      place1 = create(:place)
      place2 = create(:place)
      place3 = create(:place)
      create(:event, company: company, campaign: campaign, place: place1)
      create(:event, company: company, campaign: campaign, place: place2)
      create(:event, company: company, campaign: campaign, place: place3)
      Sunspot.commit
      get :index, page: 2, company_id: company.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 0
      expect(result['total']).to eql 3
      expect(result['page']).to eql 2
      expect(result['results']).to be_empty
    end

    it 'return a list of venues filtered by campaign id', :inline_jobs do
      campaign = create(:campaign, company: company)
      other_campaign = create(:campaign, company: company)
      venue = create(:venue, place: create(:place), company: company)
      other_venue = create(:venue, place: create(:place), company: company)
      create(:event, company: company, campaign: campaign, place: venue.place)
      create(:event, company: company, campaign: other_campaign, place: other_venue.place)
      Sunspot.commit

      get :index, campaign: [campaign.id], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(1)
      expect(result['results'].first).to include('id' => venue.id)
    end
  end

  describe "GET 'show'" do
    before do
      Kpi.create_global_kpis
    end

    let(:venue) { create(:venue, company: company, place: create(:place, is_custom_place: true, reference: nil)) }

    it 'returns http success' do
      get 'show', id: venue.to_param, format: :json
      expect(response).to be_success
      expect(response).to render_template('show')
    end
  end

  describe "GET 'photos'", search: true do
    it 'returns http success' do
      campaign = create(:campaign, company: company)
      place = create(:place, name: 'Casa de Doña Lela', formatted_address: '1234 Tres Rios', is_custom_place: true, reference: nil)
      event = create(:event, company: company, campaign: campaign, place: place)
      create_list(:photo, 3, attachable: event)
      Sunspot.commit

      get 'photos', id: event.venue.to_param, format: :json
      expect(response).to be_success

      expect(json.count).to eq(3)
      expect(json.first.keys).to match_array(%w(
        id file_content_type file_file_name file_file_size created_at active file_medium
        file_thumbnail file_original file_small processed))
    end
  end

  describe "GET 'types'", search: true do
    it 'should return a list of types' do
      get :types, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to include('name' => 'Accounts', 'value' => 'accounts')
    end
  end

  describe "POST 'create'" do
    it 'should create a new place that is no found in google places' do
      expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
      expect_any_instance_of(GooglePlaces::Client).to receive(:spots).and_return([])
      expect_any_instance_of(described_class).to receive(:open).and_return(double(
        read: ActiveSupport::JSON.encode(
          'results' => [{
            'geometry' => { 'location' => { 'lat' => '1.2322', lng: '-3.23455' } } }])))
      expect do
        post 'create', venue: { name: "Guille's place", street_number: 'Tirrases',
                                route: 'La Colina', city: 'Curridabat', state: 'San José',
                                zipcode: '12345', country: 'CR', types: 'bar,restaurant' },
                       format: :json
        expect(response).to be_success
      end.to change(Place, :count).by(1)
      place = Place.last
      expect(place.name).to eql "Guille's place"
      expect(place.street_number).to eql 'Tirrases'
      expect(place.route).to eql 'La Colina'
      expect(place.city).to eql 'Curridabat'
      expect(place.state).to eql 'San José'
      expect(place.zipcode).to eql '12345'
      expect(place.country).to eql 'CR'
      expect(place.types).to eql %w(bar restaurant)
      expect(place.latitude).to eql 1.2322
      expect(place.longitude).to eql -3.23455
    end

    it 'require valid data' do
      expect do
        post 'create', venue: {
          name: "Guille's place", types: 'bar,restaurant',
          country: nil, state: nil, street_number: nil, website: nil, zipcode: nil }, format: :json
        expect(response.response_code).to eql 400
      end.to_not change(Place, :count)
      expect(json['success']).to be_falsey
    end
  end

  describe "GET 'comments'" do
    it 'returns the list of comments for the venue' do
      place = create(:place, name: 'Bar Prueba', is_custom_place: true, reference: nil)
      event = create(:approved_event, company: company, campaign: create(:campaign, company: company), place: place)
      comment1 = create(:comment, content: 'Comment #1', commentable: event, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      comment2 = create(:comment, content: 'Comment #2', commentable: event, created_at: Time.zone.local(2013, 8, 23, 9, 15))

      get 'comments', id: event.venue.id, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(2)
      expect(result).to match_array [
        {
          'id' => comment2.id,
          'content' => 'Comment #2',
          'created_at' => '2013-08-23T09:15:00.000-07:00',
          'created_by' => { 'id' => user.id, 'full_name' => user.full_name },
          'type' => 'brandscopic'
        },
        {
          'id' => comment1.id,
          'content' => 'Comment #1',
          'created_at' => '2013-08-22T11:59:00.000-07:00',
          'created_by' => { 'id' => user.id, 'full_name' => user.full_name },
          'type' => 'brandscopic'
        }]
    end
  end

  describe "GET 'search'", search: true do
    it 'return a list of events' do
      venue = create(:venue,
                     company: company,
                     place: create(:place, name: 'Casa de Doña Lela',
                                           formatted_address: '1234 Tres Rios'))
      Sunspot.commit

      get :search, term: 'lela', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result.first).to include(
        'value' => 'Casa de Doña Lela, 1234 Tres Rios',
        'label' => 'Casa de Doña Lela, 1234 Tres Rios',
        'id' => venue.place_id)
    end
  end

  describe "GET 'autocomplete'", search: true do
    it 'should return the correct buckets in the right order' do
      get 'autocomplete', q: '', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq(%w(Places Campaigns Brands People))
    end

    it 'should return the users in the People Bucket' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'gu', format: :json
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{
                                             'label' => '<i>Gu</i>illermo Vargas',
                                             'value' => company_user.id.to_s,
                                             'type' => 'user' }])
    end

    it 'should return the teams in the People Bucket' do
      team = create(:team, name: 'Spurs', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', q: 'sp', format: :json
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'should return the teams and users in the People Bucket' do
      team = create(:team, name: 'Valladolid', company_id: company.id)
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'va', format: :json
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Va</i>lladolid',
          'value' => team.id.to_s,
          'type' => 'team' },
        { 'label' => 'Guillermo <i>Va</i>rgas',
          'value' => company_user.id.to_s,
          'type' => 'user' }])
    end

    it 'should return the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', q: 'cac', format: :json
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{
                                                'label' => '<i>Cac</i>ique para todos',
                                                'value' => campaign.id.to_s,
                                                'type' => 'campaign' }])
    end

    it 'should return the brands in the Brands Bucket' do
      brand = create(:brand, name: 'Cacique', company_id: company.to_param)
      Sunspot.commit

      get 'autocomplete', q: 'cac', format: :json
      expect(response).to be_success

      brands_bucket = json.select { |b| b['label'] == 'Brands' }.first
      expect(brands_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
    end

    it 'should return the areas in the Places Bucket' do
      area = create(:area, company_id: company.id, name: 'Guanacaste')
      Sunspot.commit

      get 'autocomplete', q: 'gua', format: :json
      expect(response).to be_success

      places_bucket = json.select { |b| b['label'] == 'Places' }.first
      expect(places_bucket['value']).to eq([{ 'label' => '<i>Gua</i>nacaste', 'value' => area.id.to_s, 'type' => 'area' }])
    end

    it 'should return the venues in the Places Bucket' do
      venue = create(:venue, company_id: company.id,
                             place: create(:place, name: 'Guanacaste'))
      Sunspot.commit

      get 'autocomplete', q: 'gua', format: :json
      expect(response).to be_success

      places_bucket = json.select { |b| b['label'] == 'Places' }.first
      expect(places_bucket['value']).to eq([{ 'label' => '<i>Gua</i>nacaste', 'value' => venue.id.to_s, 'type' => 'venue' }])
    end
  end
end
