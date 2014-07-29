require 'spec_helper'

describe Api::V1::VenuesController, :type => :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }


  describe "GET 'index'", search: true do
    it "return a list of venues", strategy: :deletion do
      campaign = FactoryGirl.create(:campaign, company: company)
      place1 = FactoryGirl.create(:place)
      place2 = FactoryGirl.create(:place)
      place3 = FactoryGirl.create(:place)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place1)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place2)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place3)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 3
      expect(result['total']).to eql 3
      expect(result['page']).to eql 1
      expect(result['results'].first.keys).to match_array ["avg_impressions", "avg_impressions_cost",
        "avg_impressions_hour", "city", "country", "events_count", "formatted_address", "id", "impressions",
        "interactions", "latitude", "longitude", "name", "promo_hours", "sampled", "score", "spent", "state",
        "zipcode", "td_linx_code"
      ]
    end

    it "second page should return no results", strategy: :deletion do
      campaign = FactoryGirl.create(:campaign, company: company)
      place1 = FactoryGirl.create(:place)
      place2 = FactoryGirl.create(:place)
      place3 = FactoryGirl.create(:place)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place1)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place2)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place3)
      Sunspot.commit
      get :index, auth_token: user.authentication_token, page: 2, company_id: company.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 0
      expect(result['total']).to eql 3
      expect(result['page']).to eql 2
      expect(result['results']).to be_empty
    end

    it "return a list of venues filtered by campaign id", strategy: :deletion do
      with_resque do
        campaign = FactoryGirl.create(:campaign, company: company)
        other_campaign = FactoryGirl.create(:campaign, company: company)
        venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: company)
        other_venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: company)
        FactoryGirl.create(:event, company: company, campaign: campaign, place: venue.place)
        FactoryGirl.create(:event, company: company, campaign: other_campaign, place: other_venue.place)
        Sunspot.commit

        get :index, auth_token: user.authentication_token, company_id: company.to_param, campaign: [campaign.id], format: :json
        expect(response).to be_success
        result = JSON.parse(response.body)

        expect(result['results'].count).to eq(1)
        expect(result['results'].first).to include({'id' => venue.id})
      end
    end

    it "return the facets for the search", strategy: :deletion do
      with_resque do
        campaign = FactoryGirl.create(:campaign, company: company)
        place = FactoryGirl.create(:place)
        FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
        Sunspot.commit

        get :index, auth_token: user.authentication_token, company_id: company.to_param, format: :json
        expect(response).to be_success
        result = JSON.parse(response.body)

        expect(result['results'].count).to eql 1
        expect(result['facets'].map{|f| f['label'] }).to match_array ["$ Spent", "Areas", "Brands", "Campaigns", "Events", "Impressions", "Interactions", "Price", "Promo Hours", "Samples", "Venue Score"]
      end
    end

    it "should not include the facets when the page is greater than 1" do
      get :index, auth_token: user.authentication_token, company_id: company.to_param, page: 2, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result['results']).to eq([])
      expect(result['facets']).to be_nil
      expect(result['page']).to eq(2)
    end
  end

  describe "GET 'show'" do
    before do
      Kpi.create_global_kpis
    end

    let(:venue) { FactoryGirl.create(:venue, company: company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil)) }

    it "returns http success" do
      get 'show', auth_token: user.authentication_token, company_id: company.to_param, id: venue.to_param, format: :json
      expect(response).to be_success
      expect(response).to render_template('show')
    end
  end

  describe "GET 'photos'", search: true do
    it "returns http success" do
      campaign = FactoryGirl.create(:campaign, company: company)
      place = FactoryGirl.create(:place, name: 'Casa de Doña Lela', formatted_address: '1234 Tres Rios', is_custom_place: true, reference: nil)
      event = FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
      photos = FactoryGirl.create_list(:photo, 3, attachable: event)
      Sunspot.commit

      get 'photos', auth_token: user.authentication_token, company_id: company.to_param, id: event.venue.to_param, format: :json
      result = JSON.parse(response.body)
      expect(response).to be_success
      expect(response).to render_template('photos')

      expect(result.count).to eq(3)
    end
  end

  describe "GET 'types'", search: true do
    it "should return a list of types" do
      get :types, auth_token: user.authentication_token, company_id: company.to_param, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to include('name' => 'Accounts', 'value' => 'accounts')
    end
  end

  describe "POST 'create'" do
    it "should create a new place that is no found in google places" do
      expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
      expect_any_instance_of(GooglePlaces::Client).to receive(:spots).and_return([])
      expect_any_instance_of(GooglePlaces::Client).to receive(:spot).and_return(double(opening_hours: {}))
      expect(HTTParty).to receive(:post).and_return({'reference' => 'ABC', 'id' => 'XYZ'})
      expect_any_instance_of(Api::V1::VenuesController).to receive(:open).and_return(double(read: ActiveSupport::JSON.encode({'results' => [{'geometry' => { 'location' => {'lat' => '1.2322', lng: '-3.23455'}}}]})))
      expect {
        post 'create', auth_token: user.authentication_token, company_id: company.to_param, venue: {name: "Guille's place", street_number: 'Tirrases', route: 'La Colina', city: 'Curridabat', state: 'San José', zipcode: '12345', country: 'CR', types: 'bar,restaurant'}, format: :json
        expect(response).to be_success
      }.to change(Place, :count).by(1)
      place = Place.last
      expect(place.name).to eql "Guille's place"
      expect(place.street_number).to eql 'Tirrases'
      expect(place.route).to eql 'La Colina'
      expect(place.city).to eql 'Curridabat'
      expect(place.state).to eql 'San José'
      expect(place.zipcode).to eql '12345'
      expect(place.country).to eql 'CR'
      expect(place.latitude).to eql 1.2322
      expect(place.longitude).to eql -3.23455
    end
  end

  describe "GET 'comments'" do
    it "returns the list of comments for the venue" do
      place = FactoryGirl.create(:place, name: 'Bar Prueba', is_custom_place: true, reference: nil)
      event = FactoryGirl.create(:approved_event, company: company, campaign: FactoryGirl.create(:campaign, company: company), place: place)
      comment1 = FactoryGirl.create(:comment, content: 'Comment #1', commentable: event, created_at: Time.zone.local(2013, 8, 22, 11, 59))
      comment2 = FactoryGirl.create(:comment, content: 'Comment #2', commentable: event, created_at: Time.zone.local(2013, 8, 23, 9, 15))

      get 'comments', auth_token: user.authentication_token, company_id: company.to_param, id: event.venue.id, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result.count).to eq(2)
      expect(result).to match_array [{
                         'id' => comment2.id,
                         'content' => 'Comment #2',
                         'created_at' => '2013-08-23T09:15:00-07:00',
                         'type' => 'brandscopic'
                        },
                        {
                         'id' => comment1.id,
                         'content' => 'Comment #1',
                         'created_at' => '2013-08-22T11:59:00-07:00',
                         'type' => 'brandscopic'
                        }]
    end
  end

  describe "GET 'search'", search: true do
    it "return a list of events" do
      campaign = FactoryGirl.create(:campaign, company: company)
      venue = FactoryGirl.create(:venue, company: company, place: FactoryGirl.create(:place, name: 'Casa de Doña Lela', formatted_address: '1234 Tres Rios'))
      Sunspot.commit

      get :search, auth_token: user.authentication_token, company_id: company.to_param, term: 'lela', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result.first).to include("value"=>"Casa de Doña Lela, 1234 Tres Rios", "label"=> "Casa de Doña Lela, 1234 Tres Rios", "id"=>venue.place_id)
    end
  end


  describe "GET 'autocomplete'", search: true do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: '', format: :json
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map{|b| b['label']}).to eq(['Campaigns', 'Brands', 'Areas', 'People'])
    end

    it "should return the users in the People Bucket" do
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'gu', format: :json
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      expect(people_bucket['value']).to eq([{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}])
    end

    it "should return the teams in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Spurs', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'sp', format: :json
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      expect(people_bucket['value']).to eq([{"label"=>"<i>Sp</i>urs", "value" => team.id.to_s, "type"=>"team"}])
    end

    it "should return the teams and users in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Valladolid', company_id: company.id)
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'va', format: :json
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      expect(people_bucket['value']).to eq([{"label"=>"<i>Va</i>lladolid", "value"=>team.id.to_s, "type"=>"team"}, {"label"=>"Guillermo <i>Va</i>rgas", "value"=>company_user.id.to_s, "type"=>"company_user"}])
    end

    it "should return the campaigns in the Campaigns Bucket" do
      campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'cac', format: :json
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
      expect(campaigns_bucket['value']).to eq([{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}])
    end

    it "should return the brands in the Brands Bucket" do
      brand = FactoryGirl.create(:brand, name: 'Cacique',company_id: company.to_param)
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'cac', format: :json
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      brands_bucket = buckets.select{|b| b['label'] == 'Brands'}.first
      expect(brands_bucket['value']).to eq([{"label"=>"<i>Cac</i>ique", "value"=>brand.id.to_s, "type"=>"brand"}])
    end

    it "should return the venues in the Places Bucket" do
      area = FactoryGirl.create(:area, company_id: company.id, name: 'Guanacaste')
      Sunspot.commit

      get 'autocomplete', auth_token: user.authentication_token, company_id: company.to_param, q: 'gua', format: :json
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select{|b| b['label'] == 'Areas'}.first
      expect(places_bucket['value']).to eq([{"label"=>"<i>Gua</i>nacaste", "value"=>area.id.to_s, "type"=>"area"}])
    end
  end
end