require 'rails_helper'

feature "Activity Types", js: true do
  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
    allow_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  feature "List view", search: true  do
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

      click_js_button 'New Activity Type'

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

    scenario "should allow user to deactivate activity types" do
      FactoryGirl.create(:activity_type, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: true, company: @company)
      Sunspot.commit
      visit activity_types_path

      expect(page).to have_content('A Vinos ticos')
      within("ul#activity_types-list li:nth-child(1)") do
        click_js_link('Deactivate')
      end
      confirm_prompt 'Are you sure you want to deactivate this activity type?'

      expect(page).to have_no_content('A Vinos ticos')
    end

    scenario "should allow user to activate activity type" do
      FactoryGirl.create(:activity_type, name: 'A Vinos ticos', description: 'Algunos vinos de Costa Rica', active: false, company: @company)
      Sunspot.commit
      visit activity_types_path

      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      expect(page).to have_content('A Vinos ticos')
      within("ul#activity_types-list li:nth-child(1)") do
        click_js_link('Activate')
      end
      expect(page).to have_no_content('A Vinos ticos')
    end

    scenario "should allow user to edit an activity type" do
      FactoryGirl.create(:activity_type, name: 'A test activity type', description: 'Algunos vinos de Costa Rica', company: @company)
      Sunspot.commit
      visit activity_types_path

      expect(page).to have_content('A test activity type')
      within("ul#activity_types-list li:nth-child(1)") do
        click_js_link('Edit')
      end

      within visible_modal do
        fill_in 'Name', with: 'Drink feature'
        fill_in 'Description', with: 'A description for drink feature type'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within("ul#activity_types-list li:nth-child(1)") do
        expect(page).to have_no_content('A test activity type')
        expect(page).to have_content('Drink feature')
        expect(page).to have_content('A description for drink feature type')
      end
    end
  end

  feature "Details view" do
    scenario "should allow user to edit an activity type" do
      activity_type = FactoryGirl.create(:activity_type, name: 'A test activity type', description: 'Algunos vinos de Costa Rica', company: @company)
      Sunspot.commit
      visit activity_type_path(activity_type)

      expect(page).to have_selector('h2', text: 'A test activity type')
      find('.links-data').click_js_button('Edit Activity Type')

      within visible_modal do
        fill_in 'Name', with: 'Drink feature'
        fill_in 'Description', with: 'A description for drink feature type'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'Drink feature')
      expect(page).to have_selector('div.description-data', text: 'A description for drink feature type')
    end
  end
end
