require 'spec_helper'

feature "DayParts", search: true, js: true do

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

  feature "/day_parts" do
    scenario "GET index should display a table with the day_parts" do
      day_parts = [
        FactoryGirl.create(:day_part, company: @company, name: 'Morningns', description: 'From 8 to 11am', active: true),
        FactoryGirl.create(:day_part, company: @company, name: 'Afternoons', description: 'From 1 to 6pm', active: true)
      ]
      Sunspot.commit
      visit day_parts_path

      within("ul#day_parts-list") do
        # First Row
        within("li:nth-child(1)") do
          page.should have_content('Afternoons')
          page.should have_content('From 1 to 6pm')
        end
        # Second Row
        within("li:nth-child(2)") do
          page.should have_content('Morningns')
          page.should have_content('From 8 to 11am')
        end
      end
    end

    scenario "should allow user to activate/deactivate Day Parts" do
      FactoryGirl.create(:day_part, company: @company, name: 'Morning', active: true)
      Sunspot.commit
      visit day_parts_path

      within("ul#day_parts-list") do
        click_link('Deactivate')
      end
      within visible_modal do
        page.should have_content('Are you sure you want to deactivate this day part?')
        click_link("OK")
      end
      ensure_modal_was_closed

      within("ul#day_parts-list") do
        page.should have_no_content('Morning')
      end

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within("ul#day_parts-list") do
        page.should have_content('Morning')
        click_link('Activate')
        page.should have_no_content('Morning')
      end
    end

    it 'allows the user to create a new day part' do
      visit day_parts_path

      click_link('New Day part')

      within visible_modal do
        fill_in 'Name', with: 'new day part name'
        fill_in 'Description', with: 'new day part description'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new day part name') # Wait for the page to load
      page.should have_selector('h2', text: 'new day part name')
      page.should have_selector('div.description-data', text: 'new day part description')
    end
  end

  feature "/day_parts/:day_part_id", :js => true do
    scenario "GET show should display the day_part details page" do
      day_part = FactoryGirl.create(:day_part, company: @company, name: 'Some day part', description: 'a day part description')
      visit day_part_path(day_part)
      page.should have_selector('h2', text: 'Some day part')
      page.should have_selector('div.description-data', text: 'a day part description')
    end

    it 'diplays a table of dates within the day part' do
      day_part = FactoryGirl.create(:day_part, company: @company,
          day_items:[
            FactoryGirl.create(:day_item, start_time: '12:00pm', end_time: '4:00pm'),
            FactoryGirl.create(:day_item, start_time: '1:00pm', end_time: '3:00pm')
          ]
      )
      visit day_part_path(day_part)
      within('#day-part-days-list') do
        within(".date-item:nth-child(1)") do
          page.should have_content('From 12:00 PM to 4:00 PM')
        end
        within(".date-item:nth-child(2)") do
          page.should have_content('From 1:00 PM to 3:00 PM')
        end
      end
    end

    it 'allows the user to activate/deactivate a day part' do
      day_part = FactoryGirl.create(:day_part, company: @company, active: true)
      visit day_part_path(day_part)
      find('.links-data').click_link('Deactivate')
      within visible_modal do
        page.should have_content('Are you sure you want to deactivate this day part?')
        click_link("OK")
      end
      ensure_modal_was_closed
      find('.links-data').click_link('Activate')
    end

    it 'allows the user to edit the day_part' do
      day_part = FactoryGirl.create(:day_part, company: @company)
      visit day_part_path(day_part)

      find('.links-data').click_link('Edit')

      within("form#edit_day_part_#{day_part.id}") do
        fill_in 'Name', with: 'edited day part name'
        fill_in 'Description', with: 'edited day part description'
        click_button 'Save'
      end
      ensure_modal_was_closed
      page.find('h2', text: 'edited day part name') # Make su the page is reloaded
      page.should have_selector('h2', text: 'edited day part name')
      page.should have_selector('div.description-data', text: 'edited day part description')
    end

    it 'allows the user to add and remove date items to the day part' do
      day_part = FactoryGirl.create(:day_part, company: @company)
      date_item = FactoryGirl.create(:date_item) # Create the date_item to be added
      visit day_part_path(day_part)

      click_link('Add Time')

      within visible_modal do
        fill_in 'Start', with: '1:00am'
        fill_in 'End', with: '4:00am'
        click_js_button "Add"
      end

      ensure_modal_was_closed

      day_item_text = 'From 1:00 AM to 4:00 AM'
      page.should have_content(day_item_text)
      within("#day-part-days-list .date-item") do
        click_link('Remove')
      end
      page.should have_no_content(day_item_text)

    end
  end
end
