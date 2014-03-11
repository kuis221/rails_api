require 'spec_helper'

feature "ActivityTypes", search: true, js: true do

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

  feature "/activity_types" do
    scenario "GET index should display a table with the day_parts" do
      activity_types = [
        FactoryGirl.create(:activity_type, company: @company, name: 'Morningns', description: 'From 8 to 11am', active: true),
        FactoryGirl.create(:activity_type, company: @company, name: 'Afternoons', description: 'From 1 to 6pm', active: true)
      ]
      Sunspot.commit
      visit activity_types_path

      within("ul#activity_types-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Afternoons')
          expect(page).to have_content('From 1 to 6pm')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Morningns')
          expect(page).to have_content('From 8 to 11am')
        end
      end
    end
    
    scenario 'allows the user to create a new activity type' do
      visit activity_types_path

      click_js_button 'New Activity type'

      within visible_modal do
        fill_in 'Name', with: 'Activity Type name'
        fill_in 'Description', with: 'activity type description'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'Activity Type name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'Activity Type name')
      expect(page).to have_selector('div.description-data', text: 'activity type description')
    end
  end
end
