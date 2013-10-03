require 'spec_helper'

describe PlacesController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  let(:area){ FactoryGirl.create(:area, company: @company) }
  let(:place){ FactoryGirl.create(:place) }

  describe "POST 'create'" do
    it "returns http success" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      post 'create', area_id: area.id, place: {reference: ":ref||:id"}, format: :js
      response.should be_success
    end

    it "should create a new place that is no found in google places" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      GooglePlaces::Client.any_instance.should_receive(:spots).and_return([])
      HTTParty.should_receive(:post).and_return({'reference' => 'ABC', 'id' => 'XYZ'})
      PlacesController.any_instance.should_receive(:open).and_return(double(read: ActiveSupport::JSON.encode({'results' => [{'geometry' => { 'location' => {'lat' => '1.2322', lng: '-3.23455'}}}]})))
      expect {
        post 'create', area_id: area.id, add_new_place: true, place: {name: "Guille's place", street_number: '123 st', route: 'xyz 321', city: 'Curri', state: 'San Jose', zipcode: '12345', country: 'Costa Rica'}, format: :js
      }.to change(Place, :count).by(1)
      place = Place.last
      place.name = "Guille's place"
      place.street_number = '123 st'
      place.route = 'xyz 321'
      place.city = 'Curri'
      place.state = 'San Jose'
      place.zipcode = '12345'
      place.country = 'Costa Rica'

      area.places.should == [place]
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', area_id: area.id, format: :js
      response.should be_success
      response.should render_template('new')
      response.should render_template('form')
    end
  end

  describe "DELETE 'destroy'" do
    it "should delete the link within the area and the place" do
      area.places << place
      expect {
        expect {
          delete 'destroy', area_id: area.to_param, id: place.id, format: :js
          response.should be_success
        }.to change(Placeable, :count).by(-1)
      }.to_not change(Area, :count)
    end
  end

end