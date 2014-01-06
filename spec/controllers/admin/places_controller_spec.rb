require 'spec_helper'

describe Admin::PlacesController do
  before do
    @user = FactoryGirl.create(:admin_user)
    sign_in @user
  end

  let(:place) { FactoryGirl.create(:place) }

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      response.should be_success
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: place.to_param
      response.should be_success
      assigns(:place).should == place
    end
  end

  describe "PUT 'update'" do
    it "returns http success" do
      put 'update', id: place.to_param, place: {name: 'New Name', city: 'Curri', state: 'SJ', country: 'CR', zipcode: '12345', street_number: '562', route: 'calle123'}
      response.should redirect_to(admin_place_path(place))
      assigns(:place).should == place
      place.reload
      place.name.should == 'New Name'
      place.country.should == 'CR'
      place.state.should == 'SJ'
      place.city.should == 'Curri'
      place.zipcode.should == '12345'
      place.street_number.should == '562'
      place.route.should == 'calle123'
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      #p place.inspect
      get 'show', id: place.to_param
      response.should be_success
      assigns(:place).should == place
    end
  end
end