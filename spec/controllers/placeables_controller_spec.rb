require 'spec_helper'

describe PlaceablesController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  let(:campaign) { FactoryGirl.create(:campaign, company: @company) }
  let(:company_user) { FactoryGirl.create(:company_user, company: @company) }

  describe "GET 'new'" do
    it "should include all the active areas" do
      area = FactoryGirl.create(:area, company: @company)
      inactive_area = FactoryGirl.create(:area, company: @company, active: false)

      get :new, campaign_id: campaign.id, format: :js

      expect(response).to be_success

      expect(assigns(:areas)).to eq([area])
    end

    it "do not include the areas that belongs to the campaign" do
      area = FactoryGirl.create(:area, company: @company)
      assigned_area = FactoryGirl.create(:area, company: @company)
      campaign.areas << assigned_area
      get :new, campaign_id: campaign.id, format: :js

      expect(response).to be_success

      expect(assigns(:areas)).to eq([area])
    end

    it "do not include the areas that belongs to the company user" do
      area = FactoryGirl.create(:area, company: @company)
      assigned_area = FactoryGirl.create(:area, company: @company)
      company_user.areas << assigned_area
      get :new, company_user_id: company_user.id, format: :js

      expect(response).to be_success

      expect(assigns(:areas)).to eq([area])
    end
  end

  describe "POST 'add_area'" do
    let(:area) {FactoryGirl.create(:area, company: @company)}
    it "should add the area to the campaign" do
      expect {
        post 'add_area', campaign_id: campaign.id, area: area.id, format: :js
      }.to change(campaign.areas, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('placeables/add_area')
    end

    it "should add the area to the company user" do
      expect(Rails.cache).to receive(:delete).with("user_accessible_locations_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_accessible_places_#{company_user.id}")
      expect {
        post 'add_area', company_user_id: company_user.id, area: area.id, format: :js
      }.to change(company_user.areas, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('placeables/add_area')
      expect(response).to render_template('company_users/_add_area')
    end
  end

  describe "DELETE 'remove_area'" do
    let(:area) {FactoryGirl.create(:area, company: @company)}
    let(:kpi) {FactoryGirl.create(:kpi, company: @company)}
    it "should remove the area and the goals for the associated kpis from the campaign" do
      campaign.areas << area

      area_goal = area.goals.for_kpi(kpi)
      area_goal.parent = campaign
      area_goal.value = 100
      area_goal.save

      expect {
        expect {
          delete 'remove_area', campaign_id: campaign.id, area: area.id, format: :js
        }.to change(campaign.areas, :count).by(-1)
      }.to change(Goal, :count).by(-1)

      expect(response).to be_success
      expect(response).to render_template('placeables/remove_area')
    end

    it "should remove the area from the company user" do
      company_user.areas << area

      area_goal = area.goals.for_kpi(kpi)
      area_goal.parent = company_user
      area_goal.value = 100
      area_goal.save

      expect(Rails.cache).to receive(:delete).with("user_accessible_locations_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_accessible_places_#{company_user.id}")
      expect {
        expect {
          delete 'remove_area', company_user_id: company_user.id, area: area.id, format: :js
        }.to change(company_user.areas, :count).by(-1)
      }.to change(Goal, :count).by(-1)
      expect(response).to be_success
      expect(response).to render_template('placeables/remove_area')
    end
  end
end
