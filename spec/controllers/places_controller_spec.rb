require 'spec_helper'

describe PlacesController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  let(:campaign){ FactoryGirl.create(:campaign, company: @company) }
  let(:company_user){ FactoryGirl.create(:company_user, company: @company) }
  let(:area){ FactoryGirl.create(:area, company: @company) }
  let(:place){ FactoryGirl.create(:place) }

  describe "POST 'create'" do
    it "returns http success" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      post 'create', area_id: area.id, place: {reference: ":ref||:id"}, format: :js
      expect(response).to be_success
    end

    it "should create a new place that is no found in google places" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      GooglePlaces::Client.any_instance.should_receive(:spots).and_return([])
      HTTParty.should_receive(:post).and_return({'reference' => 'ABC', 'id' => 'XYZ'})
      PlacesController.any_instance.should_receive(:open).and_return(double(read: ActiveSupport::JSON.encode({'results' => [{'geometry' => { 'location' => {'lat' => '1.2322', lng: '-3.23455'}}}]})))
      expect {
        post 'create', area_id: area.to_param, add_new_place: true, place: {name: "Guille's place", street_number: '123 st', route: 'xyz 321', city: 'Curridabat', state: 'San José', zipcode: '12345', country: 'CR'}, format: :js
      }.to change(Place, :count).by(1)
      place = Place.last
      expect(place.name).to eql "Guille's place"
      expect(place.street_number).to eql '123 st'
      expect(place.route).to eql 'xyz 321'
      expect(place.city).to eql 'Curridabat'
      expect(place.state).to eql 'San José'
      expect(place.zipcode).to eql '12345'
      expect(place.country).to eql 'CR'
      expect(place.latitude).to eql 1.2322
      expect(place.longitude).to eql -3.23455
      expect(place.locations.count).to eql 4

      expect(area.places).to match_array([place])
    end

    context "the place already exists on API" do
      it "save the user's address data if spot have not address associated" do
        GooglePlaces::Client.any_instance.should_receive(:spot).and_return(double(
          name: 'APIs place name', lat: '1.111', lng: '2.222', formatted_address: 'api fmt address', types: ['bar'],
          address_components: nil
        ))
        GooglePlaces::Client.any_instance.should_receive(:spots).and_return([double(id: '123', reference: 'XYZ')])
        PlacesController.any_instance.should_receive(:open).and_return(double(read: ActiveSupport::JSON.encode({'results' => [{'geometry' => { 'location' => {'lat' => '1.2322', lng: '-3.23455'}}}]})))
        expect {
          post 'create', area_id: area.id, add_new_place: true, place: {name: "Guille's place", street_number: '123 st', route: 'xyz 321', city: 'Curridabat', state: 'San José', zipcode: '12345', country: 'CR'}, format: :js
        }.to change(Place, :count).by(1)
        place = Place.last
        expect(place.name).to eql "APIs place name"
        expect(place.street_number).to eql '123 st'
        expect(place.route).to eql 'xyz 321'
        expect(place.city).to eql 'Curridabat'
        expect(place.state).to eql 'San José'
        expect(place.zipcode).to eql '12345'
        expect(place.country).to eql 'CR'
        expect(place.place_id).to eql '123'
        expect(place.reference).to eql 'XYZ'
        expect(place.latitude).to eql 1.111
        expect(place.longitude).to eql 2.222
        expect(place.locations.count).to eql 4

        area.places.should == [place]
      end

      it "creates the place and associate its to the campaign" do
        GooglePlaces::Client.any_instance.should_receive(:spot).and_return(double(
          name: 'APIs place name', lat: '1.111', lng: '2.222', formatted_address: 'api fmt address', types: ['bar'],
          address_components: [
            {'types' => ['country'],'short_name' => 'US', 'long_name' => 'United States'},
            {'types' => ['administrative_area_level_1'],'short_name' => 'CA', 'long_name' => 'CA'},
            {'types' => ['locality'],'short_name' => 'Manhattan Beach', 'long_name' => 'Manhattan Beach'},
            {'types' => ['postal_code'],'short_name' => '12345', 'long_name' => '12345'},
            {'types' => ['street_number'],'short_name' => '123 st', 'long_name' => '123 st'},
            {'types' => ['route'],'short_name' => 'xyz 321', 'long_name' => 'xyz 321'}
          ]
        ))
        # GooglePlaces::Client.any_instance.should_receive(:spots).and_return([double(id: '123', reference: 'XYZ')])
        # PlacesController.any_instance.should_receive(:open).and_return(double(read: ActiveSupport::JSON.encode({'results' => [{'geometry' => { 'location' => {'lat' => '1.2322', lng: '-3.23455'}}}]})))
        expect {
          post 'create', campaign_id: campaign.id, place: {reference: 'XXXXXXXXXXX||YYYYYYYYYY'}, format: :js
        }.to change(Place, :count).by(1)
        place = Place.last
        expect(place.name).to eql "APIs place name"
        expect(place.formatted_address).to eql 'api fmt address'
        expect(place.street_number).to eql '123 st'
        expect(place.route).to eql 'xyz 321'
        expect(place.city).to eql 'Manhattan Beach'
        expect(place.state).to eql 'California'
        expect(place.zipcode).to eql '12345'
        expect(place.country).to eql 'US'
        expect(place.place_id).to eql 'YYYYYYYYYY'
        expect(place.reference).to eql 'XXXXXXXXXXX'
        expect(place.latitude).to eql 1.111
        expect(place.longitude).to eql 2.222
        expect(place.types).to eql ['bar']
        expect(place.locations.count).to eql 4
        expect(place.locations.map(&:path)).to match_array [
          "north america", "north america/united states", "north america/united states/california",
          "north america/united states/california/manhattan beach"
        ]

        campaign.places.should == [place]
      end

      it "keeps the actual data if the place already exists on the DB" do
        FactoryGirl.create(:place,
            name: 'Current place name',
            formatted_address: 'api fmt address', zipcode: 44332, route: '444 cc', street_number: 'Calle 2',
            city: 'Paraiso', state: 'Cartago', country: 'CR', latitude: 1.234, longitude: -1.234,
            place_id: '123', reference: 'XYZ'
        )
        GooglePlaces::Client.any_instance.should_receive(:spots).and_return([double(id: '123', reference: 'XYZ')])
        PlacesController.any_instance.should_receive(:open).and_return(double(read: ActiveSupport::JSON.encode({'results' => [{'geometry' => { 'location' => {'lat' => '1.2322', lng: '-3.23455'}}}]})))

        expect {
          post 'create', area_id: area.id, add_new_place: true, place: {name: "Guille's place", street_number: '123 st', route: 'xyz 321', city: 'Curridabat', state: 'San Jose', zipcode: '12345', country: 'CR'}, format: :js
        }.to_not change(Place, :count)

        place = Place.last
        expect(place.name).to eql "Current place name"
        expect(place.formatted_address).to eql 'api fmt address'
        expect(place.street_number).to eql 'Calle 2'
        expect(place.route).to eql '444 cc'
        expect(place.city).to eql 'Paraiso'
        expect(place.state).to eql 'Cartago'
        expect(place.zipcode).to eql '44332'
        expect(place.country).to eql 'CR'
        expect(place.place_id).to eql '123'
        expect(place.reference).to eql 'XYZ'
        expect(place.latitude).to eql 1.234
        expect(place.longitude).to eql -1.234

        area.places.should == [place]
      end
    end

    it "adds a place to the campaing and clears the cache" do
      Rails.cache.should_receive(:delete).at_least(1).times.with("campaign_locations_#{campaign.id}")
      post 'create', campaign_id: campaign.id, place: {reference: place.to_param}, format: :js
      expect(campaign.places).to include(place)
    end

    it "validates the address" do
      expect {
        post 'create', area_id: area.to_param, add_new_place: true, place: {name: "Guille's place", street_number: '123 st', route: 'QWERTY 321', city: 'YYYYYYYYYY', state: 'XXXXXXXXXXX', zipcode: '12345', country: 'Costa Rica'}, format: :js
      }.to_not change(Place, :count)
      expect(assigns(:place).errors[:base]).to include("The entered address doesn't seems to be valid")
      expect(response).to render_template('new_place_form')
    end

    it "should render the form for new place if the place was not selected from the autocomplete for an area" do
      expect {
        post 'create', area_id: area.to_param, place: {reference: ""}, reference_display_name: "blah blah blah", format: :js
      }.to_not change(Place,:count)
      expect(response).to be_success
      expect(response).to render_template('places/_new_place_form')
      expect(response).to render_template('places/new_place')
    end

    it "should render the form for new place if the place was not selected from the autocomplete for a campaign" do
      expect {
        post 'create', campaign_id: campaign.to_param, place: {reference: ""}, reference_display_name: "blah blah blah", format: :js
      }.to_not change(Place,:count)
      expect(response).to be_success
      expect(response).to render_template('places/_new_place_form')
      expect(response).to render_template('places/new_place')
    end

    it "should render the form for new place if the place was not selected from the autocomplete for a company user" do
      expect {
        post 'create', company_user_id: company_user.to_param, place: {reference: ""}, reference_display_name: "blah blah blah", format: :js
      }.to_not change(Place,:count)
      expect(response).to be_success
      expect(response).to render_template('places/_new_place_form')
      expect(response).to render_template('places/new_place')
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', area_id: area.id, format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('form')
    end
  end

  describe "DELETE 'destroy'" do
    it "should delete the link within the area and the place" do
      area.places << place
      expect {
        expect {
          delete 'destroy', area_id: area.to_param, id: place.id, format: :js
          expect(response).to be_success
        }.to change(Placeable, :count).by(-1)
      }.to_not change(Area, :count)
    end

    it "should delete the link within the company user and the place" do
      company_user.places << place
      expect {
        expect {
          delete 'destroy', company_user_id: company_user.to_param, id: place.id, format: :js
          expect(response).to be_success
        }.to change(Placeable, :count).by(-1)
      }.to_not change(CompanyUser, :count)
    end

    it "should delete the link within the campaign and the place" do
      Rails.cache.should_receive(:delete).at_least(1).times.with("campaign_locations_#{campaign.id}")
      campaign.places << place
      expect {
        expect {
          delete 'destroy', campaign_id: campaign.to_param, id: place.id, format: :js
          expect(response).to be_success
        }.to change(Placeable, :count).by(-1)
      }.to_not change(Campaign, :count)
    end

    it "should call the method update_common_denominators" do
      area.places << place

      Area.any_instance.should_receive(:update_common_denominators)
      expect {
        expect {
          delete 'destroy', area_id: area.to_param, id: place.id, format: :js
          expect(response).to be_success
        }.to change(Placeable, :count).by(-1)
      }.to_not change(Area, :count)
    end
  end

end