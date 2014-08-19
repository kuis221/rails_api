require 'rails_helper'

describe Admin::PlacesController, :type => :controller do
  before do
    @user = FactoryGirl.create(:admin_user)
    sign_in @user
  end

  let(:place) { FactoryGirl.create(:place) }

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: place.to_param
      expect(response).to be_success
      expect(assigns(:place)).to eq(place)
    end
  end

  describe "PUT 'update'" do
    it "returns http success" do
      put 'update', id: place.to_param, place: {name: 'New Name', city: 'Curri', state: 'SJ', country: 'CR', zipcode: '12345', street_number: '562', route: 'calle123'}
      expect(response).to redirect_to(admin_place_path(place))
      expect(assigns(:place)).to eq(place)
      place.reload
      expect(place.name).to eq('New Name')
      expect(place.country).to eq('CR')
      expect(place.state).to eq('SJ')
      expect(place.city).to eq('Curri')
      expect(place.zipcode).to eq('12345')
      expect(place.street_number).to eq('562')
      expect(place.route).to eq('calle123')
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      #p place.inspect
      get 'show', id: place.to_param
      expect(response).to be_success
      expect(assigns(:place)).to eq(place)
    end
  end
end