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