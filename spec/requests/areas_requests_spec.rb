require 'spec_helper'

describe "Areas", :js => true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  describe "/areas" do
    it "GET index should display a table with the areas" do
      areas = [
        FactoryGirl.create(:area, name: 'Gran Area Metropolitana', description: 'Ciudades principales de Costa Rica', active: true),
        FactoryGirl.create(:area, name: 'Zona Norte', description: 'Ciudades del Norte de Costa Rica', active: false)
      ]
      visit areas_path

      within("table#areas-list") do
        # First Row
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content(areas[0].name)
          find('td:nth-child(2)').should have_content(areas[0].description)
          find('td:nth-child(3)').should have_content('Active')
          find('td:nth-child(4)').should have_content('Edit')
          find('td:nth-child(4)').should have_content('Deactivate')
        end
        # Second Row
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content(areas[1].name)
          find('td:nth-child(2)').should have_content(areas[1].description)
          find('td:nth-child(3)').should have_content('Inactive')
          find('td:nth-child(4)').should have_content('Edit')
          find('td:nth-child(4)').should have_content('Activate')
        end
      end

      assert_table_sorting ("table#areas-list")
    end
  end

end