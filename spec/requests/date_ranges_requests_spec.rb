require 'spec_helper'

describe "DateRanges", search: true, js: true do

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

  describe "/date_ranges" do
    it "GET index should display a table with the date_ranges" do
      date_ranges = [
        FactoryGirl.create(:date_range, company: @company, name: 'Weekdays', description: 'From monday to friday', active: true),
        FactoryGirl.create(:date_range, company: @company, name: 'Weekends', description: 'Saturday and Sunday', active: true)
      ]
      Sunspot.commit
      visit date_ranges_path

      within("table#date-ranges-list") do
        # First Row
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content('Weekdays')
          find('td:nth-child(2)').should have_content('From monday to friday')
          find('td:nth-child(3)').should have_content('Active')
          find('td:nth-child(4)').should have_content('Edit')
          find('td:nth-child(4)').should have_content('Deactivate')
        end
        # Second Row
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content('Weekends')
          find('td:nth-child(2)').should have_content('Saturday and Sunday')
          find('td:nth-child(3)').should have_content('Active')
          find('td:nth-child(4)').should have_content('Edit')
          find('td:nth-child(4)').should have_content('Deactivate')
        end
      end

      assert_table_sorting ("table#date-ranges-list")

    end

    it 'allows the user to create a new date_range' do
      visit date_ranges_path

      click_link('New Date Range')

      within("form#new_date_range") do
        fill_in 'Name', with: 'new date range name'
        fill_in 'Description', with: 'new date range description'
        click_button 'Create Date range'
      end

      find('h2', text: 'new date range name') # Wait for the page to load
      page.should have_selector('h2', text: 'new date range name')
      page.should have_selector('div.date_range-description', text: 'new date range description')
    end
  end

  describe "/date_ranges/:date_range_id", :js => true do
    it "GET show should display the date_range details page" do
      date_range = FactoryGirl.create(:date_range, company: @company, name: 'Some Date Range', description: 'a date range description')
      visit date_range_path(date_range)
      page.should have_selector('h2', text: 'Some Date Range')
      page.should have_selector('div.date_range-description', text: 'a date range description')
    end

    it 'diplays a table of dates within the date range' do
      date_range = FactoryGirl.create(:date_range, company: @company)
      date_items = [FactoryGirl.create(:date_item, start_date: '01/01/2013', end_date: nil), FactoryGirl.create(:date_item, start_date: '03/03/2013', end_date: nil)]
      date_items.map {|b| date_range.date_items << b }
      visit date_range_path(date_range)
      within('table#date_range-dates') do
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content('On 01/01/2013')
          find('td:nth-child(2)').should have_content('Remove')
        end
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content('On 03/03/2013')
          find('td:nth-child(2)').should have_content('Remove')
        end
      end

      assert_table_sorting ("table#date_range-dates")
    end

    it 'allows the user to activate/deactivate a date range' do
      date_range = FactoryGirl.create(:date_range, company: @company, active: true)
      visit date_range_path(date_range)
      within('.active-deactive-toggle') do
        page.should have_selector('a.btn-success.active', text: 'Active')
        page.should have_selector('a', text: 'Inactive')
        page.should_not have_selector('a.btn-danger', text: 'Inactive')

        click_link('Inactive')
        page.should have_selector('a.btn-danger.active', text: 'Inactive')
        page.should have_selector('a', text: 'Active')
        page.should_not have_selector('a.btn-success', text: 'Active')
      end
    end

    it 'allows the user to edit the date_range' do
      date_range = FactoryGirl.create(:date_range, company: @company)
      visit date_range_path(date_range)

      click_link('Edit')

      within("form#edit_date_range_#{date_range.id}") do
        fill_in 'Name', with: 'edited date range name'
        fill_in 'Description', with: 'edited date range description'
        click_button 'Update Date range'
      end
      sleep(1) # Wait on second to avoid a strange error
      page.find('h2', text: 'edited date range name') # Make su the page is reloaded
      page.should have_selector('h2', text: 'edited date range name')
      page.should have_selector('div.date_range-description', text: 'edited date range description')
    end

    it 'allows the user to add date items to the date range' do
      date_range = FactoryGirl.create(:date_range, company: @company)
      date_item = FactoryGirl.create(:date_item) # Create the date_item to be added
      visit date_range_path(date_range)

      click_link('Add Date')

      pending "Finish this test"

    end
  end
end
