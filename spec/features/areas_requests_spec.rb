require 'spec_helper'

feature "Areas", js: true, search: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  feature "/areas" do
    scenario "GET index should display a table with the areas" do
      areas = [
        FactoryGirl.create(:area, name: 'Gran Area Metropolitana', description: 'Ciudades principales de Costa Rica', active: true, company: @company),
        FactoryGirl.create(:area, name: 'Zona Norte', description: 'Ciudades del Norte de Costa Rica', active: true, company: @company)
      ]
      Sunspot.commit
      visit areas_path

      within("#areas-list") do
        # First Row
        within("li#area_#{areas[0].id}") do
          expect(page).to have_text('Gran Area Metropolitana')
          expect(page).to have_text('Ciudades principales de Costa Rica')
          expect(page).to have_selector('a.edit')
          expect(page).to have_selector('a.disable')
        end
        # Second Row
        within("li#area_#{areas[1].id}") do
          expect(page).to have_text('Zona Norte')
          expect(page).to have_text('Ciudades del Norte de Costa Rica')
          expect(page).to have_selector('a.edit')
          expect(page).to have_selector('a.disable')
        end
      end
      wait_for_ajax
    end

    scenario "should allow user to deactivate areas" do
      FactoryGirl.create(:area, name: 'Wild Wild West', description: 'Cowboys\' home', active: true, company: @company)
      Sunspot.commit
      visit areas_path

      expect(page).to have_text('Wild Wild West')
      within("ul#areas-list li:nth-child(1)") do
        click_link('Deactivate')
      end
      confirm_prompt "Are you sure you want to deactivate this area?"

      expect(page).to have_no_content('Wild Wild West')
      wait_for_ajax
    end

    scenario "should allow user to activate areas" do
      FactoryGirl.create(:area, name: 'Wild Wild West', description: 'Cowboys\' home', active: false, company: @company)
      Sunspot.commit
      visit areas_path

      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within("ul#areas-list li:nth-child(1)") do
        expect(page).to have_text('Wild Wild West')
        click_link('Activate')
      end
      within("ul#areas-list") do
        expect(page).to have_no_content('Wild Wild West')
      end
      wait_for_ajax
    end
  end

  feature "/areas/:area_id", :js => true do
    scenario "GET show should display the area details page" do
      area = FactoryGirl.create(:area, name: 'Some Area', description: 'an area description', company: @company)
      visit area_path(area)
      expect(page).to have_selector('h2', text: 'Some Area')
      expect(page).to have_selector('div.description-data', text: 'an area description')
    end

    scenario 'diplays a table of places within the area' do
      area = FactoryGirl.create(:area, name: 'Some do', description: 'an area description', company: @company)
      places = [FactoryGirl.create(:place, name: 'Place 1'), FactoryGirl.create(:place, name: 'Place 2')]
      places.map {|p| area.places << p }
      visit area_path(area)
      within('#area-places-list') do
        within("div.area-place:nth-child(1)") do
          expect(page).to have_text('Place 1')
          expect(page).to have_selector('a.remove-area-btn', visible: :false)
        end
        within("div.area-place:nth-child(2)") do
          expect(page).to have_text('Place 2')
          expect(page).to have_selector('a.remove-area-btn', visible: :false)
        end
      end
      wait_for_ajax
    end

    scenario 'allows the user to activate/deactivate a area' do
      area = FactoryGirl.create(:area, name: 'Some area', description: 'an area description', active: true, company: @company)
      visit area_path(area)
      within('.links-data') do
        click_link('Deactivate')
      end

      confirm_prompt "Are you sure you want to deactivate this area?"

      within('.links-data') do
        click_link('Activate')
        expect(page).to have_link('Deactivate') # test the link have changed
      end
      wait_for_ajax
    end

    scenario 'allows the user to edit the area' do
      area = FactoryGirl.create(:area, company: @company)
      visit area_path(area)

      click_link('Edit')

      within("form#edit_area_#{area.id}") do
        fill_in 'Name', with: 'edited area name'
        fill_in 'Description', with: 'edited area description'
        click_button 'Save'
      end

      #find('h2', text: 'edited area name') # Wait for the page to reload
      expect(page).to have_selector('h2', text: 'edited area name')
      expect(page).to have_selector('div.description-data', text: 'edited area description')
      wait_for_ajax
    end

  end

end