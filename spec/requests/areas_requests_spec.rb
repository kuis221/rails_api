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

    it "should allow user to deactivate areas" do
      FactoryGirl.create(:area, name: 'Wild Wild West', description: 'Cowboys\' home', active: true, company: @company)
      Sunspot.commit
      visit areas_path

      page.should have_content('Wild Wild West')
      within("ul#areas-list li:nth-child(1)") do
        click_js_link('Deactivate')
      end
      page.should have_no_content('Wild Wild West')
    end

    it "should allow user to activate areas" do
      FactoryGirl.create(:area, name: 'Wild Wild West', description: 'Cowboys\' home', active: false, company: @company)
      Sunspot.commit
      visit areas_path

      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      page.should have_content('Wild Wild West')
      within("ul#areas-list li:nth-child(1)") do
        click_js_link('Activate')
      end
      page.should have_no_content('Wild Wild West')
    end
  end

  describe "/areas/:area_id", :js => true do
    it "GET show should display the area details page" do
      area = FactoryGirl.create(:area, name: 'Some Area', description: 'an area description', company: @company)
      visit area_path(area)
      page.should have_selector('h2', text: 'Some Area')
      page.should have_selector('div.description-data', text: 'an area description')
    end

    it 'diplays a table of places within the area' do
      area = FactoryGirl.create(:area, name: 'Some do', description: 'an area description', company: @company)
      places = [FactoryGirl.create(:place, name: 'Place 1'), FactoryGirl.create(:place, name: 'Place 2')]
      places.map {|p| area.places << p }
      visit area_path(area)
      within('#area-places-list') do
        within("div.area-place:nth-child(1)") do
          page.should have_content('Place 1')
          page.should have_selector('a.remove-area-btn', visible: :false)
        end
        within("div.area-place:nth-child(2)") do
          page.should have_content('Place 2')
          page.should have_selector('a.remove-area-btn', visible: :false)
        end
      end
    end

    it 'allows the user to activate/deactivate a area' do
      area = FactoryGirl.create(:area, name: 'Some area', description: 'an area description', active: true, company: @company)
      visit area_path(area)
      within('.links-data') do
        click_js_link('Deactivate')
        page.should have_selector('a.toggle-active')

        click_js_link('Activate')
        page.should have_selector('a.toggle-inactive')
      end
    end

    it 'allows the user to edit the area' do
      area = FactoryGirl.create(:area, company: @company)
      visit area_path(area)

      click_js_link('Edit')

      within("form#edit_area_#{area.id}") do
        fill_in 'Name', with: 'edited area name'
        fill_in 'Description', with: 'edited area description'
        click_button 'Save'
      end

      find('h2', text: 'edited area name') # Wait for the page to reload
      page.should have_selector('h2', text: 'edited area name')
      page.should have_selector('div.description-data', text: 'edited area description')
    end

  end

end