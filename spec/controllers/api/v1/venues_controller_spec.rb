require 'spec_helper'

describe Api::V1::VenuesController do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }


  describe "GET 'index'", search: true do
    it "return a list of venues" do
      campaign = FactoryGirl.create(:campaign, company: company)
      place1 = FactoryGirl.create(:place)
      place2 = FactoryGirl.create(:place)
      place3 = FactoryGirl.create(:place)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place1)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place2)
      events = FactoryGirl.create(:event, company: company, campaign: campaign, place: place3)
      Sunspot.commit

      get :index, auth_token: user.authentication_token, company_id: company.to_param, format: :json
      response.should be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eql 3
      expect(result['total']).to eql 3
      expect(result['page']).to eql 1
      expect(result['results'].first.keys).to match_array ["avg_impressions", "avg_impressions_cost",
        "avg_impressions_hour", "city", "country", "events_count", "formatted_address", "id", "impressions",
        "interactions", "latitude", "longitude", "name", "promo_hours", "sampled", "score", "spent", "state",
        "zipcode"
      ]
    end

    it "return a list of venues filtered by campaign id" do
      with_resque do
        campaign = FactoryGirl.create(:campaign, company: company)
        other_campaign = FactoryGirl.create(:campaign, company: company)
        venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: company)
        other_venue = FactoryGirl.create(:venue, place: FactoryGirl.create(:place), company: company)
        FactoryGirl.create(:event, company: company, campaign: campaign, place: venue.place)
        FactoryGirl.create(:event, company: company, campaign: other_campaign, place: other_venue.place)
        Sunspot.commit

        get :index, auth_token: user.authentication_token, company_id: company.to_param, campaign: [campaign.id], format: :json
        response.should be_success
        result = JSON.parse(response.body)

        result['results'].count.should == 1
        expect(result['results'].first).to include({'id' => venue.id})
      end

    end

    it "return the facets for the search" do
      with_resque do
        campaign = FactoryGirl.create(:campaign, company: company)
        place = FactoryGirl.create(:place)
        FactoryGirl.create(:event, company: company, campaign: campaign, place: place)
        Sunspot.commit

        get :index, auth_token: user.authentication_token, company_id: company.to_param, format: :json
        response.should be_success
        result = JSON.parse(response.body)

        expect(result['results'].count).to eql 1
        expect(result['facets'].map{|f| f['label'] }).to match_array ["$ Spent", "Areas", "Brands", "Campaigns", "Events", "Impressions", "Interactions", "Price", "Promo Hours", "Samples", "Venue Score"]
      end
    end

    it "should not include the facets when the page is greater than 1" do
      get :index, auth_token: user.authentication_token, company_id: company.to_param, page: 2, format: :json
      response.should be_success
      result = JSON.parse(response.body)
      result['results'].should == []
      result['facets'].should be_nil
      result['page'].should == 2
    end
  end

  describe "GET 'show'" do
    before do
      Kpi.create_global_kpis
    end

    let(:venue) { FactoryGirl.create(:venue, company: company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil)) }

    it "returns http success" do
      get 'show', auth_token: user.authentication_token, company_id: company.to_param, id: venue.to_param
      response.should be_success
      response.should render_template('show')
    end
  end

  describe "GET 'search'", search: true do
    it "return a list of events" do
      campaign = FactoryGirl.create(:campaign, company: company)
      venue = FactoryGirl.create(:venue, company: company, place: FactoryGirl.create(:place, name: 'Casa de Doña Lela', formatted_address: '1234 Tres Rios'))
      Sunspot.commit

      get :search, auth_token: user.authentication_token, company_id: company.to_param, term: 'lela', format: :json
      response.should be_success
      result = JSON.parse(response.body)

      expect(result.first).to include("value"=>"Casa de Doña Lela, 1234 Tres Rios", "label"=> "Casa de Doña Lela, 1234 Tres Rios", "id"=>venue.place_id)
    end
  end
end