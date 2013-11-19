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

    it "should render the form for new place if the place was not selected from the autocomplete for an area" do
      expect {
        post 'create', area_id: area.to_param, place: {reference: ""}, reference_display_name: "blah blah blah", format: :js
      }.to_not change(Place,:count)
      response.should be_success
      response.should render_template('places/_new_place_form')
      response.should render_template('places/new_place')
    end

    it "should render the form for new place if the place was not selected from the autocomplete for a campaign" do
      expect {
        post 'create', campaign_id: campaign.to_param, place: {reference: ""}, reference_display_name: "blah blah blah", format: :js
      }.to_not change(Place,:count)
      response.should be_success
      response.should render_template('places/_new_place_form')
      response.should render_template('places/new_place')
    end

    it "should render the form for new place if the place was not selected from the autocomplete for a company user" do
      expect {
        post 'create', company_user_id: company_user.to_param, place: {reference: ""}, reference_display_name: "blah blah blah", format: :js
      }.to_not change(Place,:count)
      response.should be_success
      response.should render_template('places/_new_place_form')
      response.should render_template('places/new_place')
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

    it "should delete the link within the company user and the place" do
      company_user.places << place
      expect {
        expect {
          delete 'destroy', company_user_id: company_user.to_param, id: place.id, format: :js
          response.should be_success
        }.to change(Placeable, :count).by(-1)
      }.to_not change(CompanyUser, :count)
    end

    it "should delete the link within the campaign and the place" do
      campaign.places << place
      expect {
        expect {
          delete 'destroy', campaign_id: campaign.to_param, id: place.id, format: :js
          response.should be_success
        }.to change(Placeable, :count).by(-1)
      }.to_not change(Campaign, :count)
    end

    it "should call the method update_area_denominators" do
      area.places << place

      Area.any_instance.should_receive(:update_common_denominators)
      expect {
        expect {
          delete 'destroy', area_id: area.to_param, id: place.id, format: :js
          response.should be_success
        }.to change(Placeable, :count).by(-1)
      }.to_not change(Area, :count)
    end
  end

end