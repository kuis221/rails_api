require 'spec_helper'

feature "DateRanges", search: true, js: true do

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

  feature "/date_ranges" do
    scenario "GET index should display a table with the date_ranges" do
      date_ranges = [
        FactoryGirl.create(:date_range, company: @company, name: 'Weekdays', description: 'From monday to friday', active: true),
        FactoryGirl.create(:date_range, company: @company, name: 'Weekends', description: 'Saturday and Sunday', active: true)
      ]
      Sunspot.commit
      visit date_ranges_path

      within("ul#date_ranges-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Weekdays')
          expect(page).to have_content('From monday to friday')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Weekends')
          expect(page).to have_content('Saturday and Sunday')
        end
      end

    end

    scenario "should allow user to activate/deactivate Date Ranges" do
      FactoryGirl.create(:date_range, company: @company, name: 'Weekdays', description: 'From monday to friday', active: true)
      Sunspot.commit
      visit date_ranges_path

      within("ul#date_ranges-list") do
        click_link('Deactivate')
      end
      within visible_modal do
        expect(page).to have_content('Are you sure you want to deactivate this date range?')
        click_link("OK")
      end
      ensure_modal_was_closed

      within("ul#date_ranges-list") do
        expect(page).to have_no_selector('li')
      end

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within("ul#date_ranges-list") do
        expect(page).to have_content('Weekdays')
        click_link('Activate')
        expect(page).to have_no_content('Weekdays')
      end
    end

    it 'allows the user to create a new date_range' do
      visit date_ranges_path

      click_link('New Date range')

      within visible_modal do
        fill_in 'Name', with: 'new date range name'
        fill_in 'Description', with: 'new date range description'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new date range name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'new date range name')
      expect(page).to have_selector('div.description-data', text: 'new date range description')
    end
  end

  feature "/date_ranges/:date_range_id", :js => true do
    scenario "GET show should display the date_range details page" do
      date_range = FactoryGirl.create(:date_range, company: @company, name: 'Some Date Range', description: 'a date range description')
      visit date_range_path(date_range)
      expect(page).to have_selector('h2', text: 'Some Date Range')
      expect(page).to have_selector('div.description-data', text: 'a date range description')
    end

    it 'diplays a table of dates within the date range' do
      date_range = FactoryGirl.create(:date_range, company: @company)
      date_items = [FactoryGirl.create(:date_item, start_date: '01/01/2013', end_date: nil), FactoryGirl.create(:date_item, start_date: '03/03/2013', end_date: nil)]
      date_items.map {|b| date_range.date_items << b }
      visit date_range_path(date_range)
      within('#date_range-dates-list') do
        within(".date-item:nth-child(1)") do
          expect(page).to have_content('On 01/01/2013')
        end
        within(".date-item:nth-child(2)") do
          expect(page).to have_content('On 03/03/2013')
        end
      end
    end

    it 'allows the user to activate/deactivate a date range' do
      date_range = FactoryGirl.create(:date_range, company: @company, active: true)
      visit date_range_path(date_range)
      find('.links-data').click_link('Deactivate')
      within visible_modal do
        expect(page).to have_content("Are you sure you want to deactivate this date range?")
        click_link("OK")
      end
      ensure_modal_was_closed

      within('.links-data') do
        click_link('Activate')
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end

    it 'allows the user to edit the date_range' do
      date_range = FactoryGirl.create(:date_range, company: @company)
      visit date_range_path(date_range)

      find('.links-data').click_link('Edit')

      within("form#edit_date_range_#{date_range.id}") do
        fill_in 'Name', with: 'edited date range name'
        fill_in 'Description', with: 'edited date range description'
        click_button 'Save'
      end
      ensure_modal_was_closed
      page.find('h2', text: 'edited date range name') # Make su the page is reloaded
      expect(page).to have_selector('h2', text: 'edited date range name')
      expect(page).to have_selector('div.description-data', text: 'edited date range description')
    end

    it 'allows the user to add and remove date items to the date range' do
      date_range = FactoryGirl.create(:date_range, company: @company)
      date_item = FactoryGirl.create(:date_item) # Create the date_item to be added
      visit date_range_path(date_range)

      click_link('Add Date')

      within visible_modal do
        find("#calendar_start_date").click_link '25'
        find("#calendar_end_date").click_link '26'
        click_js_button "Create"
      end

      ensure_modal_was_closed

      expect(page).to have_selector('#date_range-dates-list div[id^=date_item]')
      within("#date_range-dates-list .date-item") do
        click_link('Remove')
      end
      expect(page).to have_no_selector('#date_range-dates-list div[id^=date_item]')

    end
  end
end
