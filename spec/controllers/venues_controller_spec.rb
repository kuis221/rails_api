require 'spec_helper'

describe VenuesController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  describe "GET 'show'" do
    before do
      Kpi.create_global_kpis
    end

    let(:venue) { FactoryGirl.create(:venue, company: @company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil)) }

    it "returns http success" do
      get 'show', id: venue.to_param
      response.should be_success
    end
  end

  describe "GET 'select_areas'" do
    let(:venue) { FactoryGirl.create(:venue, company: @company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil)) }

    it "returns http success" do
      area = FactoryGirl.create(:area, company: @company)

      # Another area already in venue
      assigned_area = FactoryGirl.create(:area, company: @company)

      venue.place.areas << assigned_area
      get 'select_areas', id: venue.to_param, format: :js
      response.should be_success
      response.should render_template('select_areas')

      assigns(:areas).should == [area]
    end
  end

  describe "POST #add_areas" do
    let(:venue) { FactoryGirl.create(:venue, company: @company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil)) }

    it "adds the area to the place" do
      area = FactoryGirl.create(:area, company: @company)
      expect {
        post 'add_areas', id: venue.to_param, area_id: area.to_param, format: :js
      }.to change(venue.place.areas, :count).by(1)
    end
  end

  describe "DELETE #delete_area" do
    let(:venue) { FactoryGirl.create(:venue, company: @company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil)) }

    it "adds the area to the place" do
      area = FactoryGirl.create(:area, company: @company)
      venue.place.areas << area
      expect {
        delete 'delete_area', id: venue.to_param, area_id: area.to_param, format: :js
      }.to change(venue.place.areas, :count).by(-1)
    end
  end

end
