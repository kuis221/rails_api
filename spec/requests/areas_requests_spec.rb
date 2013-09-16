require 'spec_helper'

describe "Areas", js: true, search: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  describe "/areas" do
    it "GET index should display a table with the areas" do
      areas = [
        FactoryGirl.create(:area, name: 'Gran Area Metropolitana', description: 'Ciudades principales de Costa Rica', active: true, company: @company),
        FactoryGirl.create(:area, name: 'Zona Norte', description: 'Ciudades del Norte de Costa Rica', active: true, company: @company)
      ]
      Sunspot.commit
      visit areas_path

      within("#areas-list") do
        # First Row
        within("li#area_#{areas[0].id}") do
          page.should have_content('Gran Area Metropolitana')
          page.should have_content('Ciudades principales de Costa Rica')
          page.should have_selector('a.edit')
          page.should have_selector('a.disable')
        end
        # Second Row
        within("li#area_#{areas[1].id}") do
          page.should have_content('Zona Norte')
          page.should have_content('Ciudades del Norte de Costa Rica')
          page.should have_selector('a.edit')
          page.should have_selector('a.disable')
        end
      end

    end
  end

end