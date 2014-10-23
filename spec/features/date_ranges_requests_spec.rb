require 'rails_helper'

feature 'DateRanges', search: true, js: true do
  let(:user) { create(:user, company: company, role_id: create(:role).id) }
  let(:company) { create(:company) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  after do
    Warden.test_reset!
  end

  feature '/date_ranges' do
    scenario 'GET index should display a table with the date_ranges' do
      create(:date_range, company: company, name: 'Weekdays', description: 'From monday to friday', active: true)
      create(:date_range, company: company, name: 'Weekends', description: 'Saturday and Sunday', active: true)
      Sunspot.commit
      visit date_ranges_path

      # First Row
      within resource_item 1 do
        expect(page).to have_content('Weekdays')
        expect(page).to have_content('From monday to friday')
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content('Weekends')
        expect(page).to have_content('Saturday and Sunday')
      end
    end

    scenario 'should allow user to activate/deactivate Date Ranges' do
      create(:date_range, company: company, name: 'Weekdays', description: 'From monday to friday', active: true)
      Sunspot.commit
      visit date_ranges_path

      within resource_item 1 do
        click_js_button 'Deactivate Date Range'
      end

      confirm_prompt 'Are you sure you want to deactivate this date range?'

      expect(page).to have_no_text 'Weekdays'

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within resource_item 1 do
        expect(page).to have_content('Weekdays')
        click_js_button 'Activate Date Range'
      end
      expect(page).to have_no_content('Weekdays')
    end

    scenario 'allows the user to create a new date_range' do
      visit date_ranges_path

      click_js_button 'New Date Range'

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

  feature '/date_ranges/:date_range_id', js: true do
    scenario 'GET show should display the date_range details page' do
      date_range = create(:date_range, company: company, name: 'Some Date Range', description: 'a date range description')
      visit date_range_path(date_range)
      expect(page).to have_selector('h2', text: 'Some Date Range')
      expect(page).to have_selector('div.description-data', text: 'a date range description')
    end

    scenario 'diplays a table of dates within the date range' do
      date_range = create(:date_range, company: company)
      date_items = [create(:date_item, start_date: '01/01/2013', end_date: nil), create(:date_item, start_date: '03/03/2013', end_date: nil)]
      date_items.map { |b| date_range.date_items << b }
      visit date_range_path(date_range)
      within('#date_range-dates-list') do
        within('.date-item:nth-child(1)') do
          expect(page).to have_content('On 01/01/2013')
        end
        within('.date-item:nth-child(2)') do
          expect(page).to have_content('On 03/03/2013')
        end
      end
    end

    scenario 'allows the user to activate/deactivate a date range' do
      date_range = create(:date_range, company: company, active: true)
      visit date_range_path(date_range)
      find('.links-data').click_js_button('Deactivate Date Range')

      confirm_prompt 'Are you sure you want to deactivate this date range?'

      within('.links-data') do
        click_js_button 'Activate Date Range'
        expect(page).to have_button 'Deactivate Date Range' # test the link have changed
      end
    end

    scenario 'allows the user to edit the date_range' do
      date_range = create(:date_range, name: 'Old name', company: company)
      visit date_range_path(date_range)
      expect(page).to have_content('Old name')

      find('.links-data').click_js_button('Edit Date Range')

      within("form#edit_date_range_#{date_range.id}") do
        fill_in 'Name', with: 'edited date range name'
        fill_in 'Description', with: 'edited date range description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed
      expect(page).to have_no_content('Old name')
      page.find('h2', text: 'edited date range name') # Make su the page is reloaded
      expect(page).to have_selector('h2', text: 'edited date range name')
      expect(page).to have_selector('div.description-data', text: 'edited date range description')
    end

    scenario 'allows the user to add and remove date items to the date range' do
      date_range = create(:date_range, company: company)
      visit date_range_path(date_range)

      click_js_link('Add Date')

      within visible_modal do
        find('#calendar_start_date').click_js_link '25'
        find('#calendar_end_date').click_js_link '26'
        click_js_button 'Create'
      end

      ensure_modal_was_closed

      expect(page).to have_selector('#date_range-dates-list div[id^=date_item]')
      within('#date_range-dates-list .date-item') do
        click_js_link 'Remove'
      end
      expect(page).to have_no_selector('#date_range-dates-list div[id^=date_item]')
    end
  end

  feature 'export' do
    let(:date_range1) { create(:date_range,
                              company: @company, name: 'Weekdays',
                              description: 'From monday to friday', active: true) }
    let(:date_range2) { create(:date_range,
                              company: @company, name: 'Weekends',
                              description: 'Saturday and Sunday', active: true) }

    before do
      # make sure tasks are created before
      date_range1
      date_range2
      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit date_ranges_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ["NAME", "DESCRIPTION"],
        ["Weekdays", "From monday to friday"],
        ["Weekends", "Saturday and Sunday"]
      ])
    end

    scenario 'should be able to export as PDF' do
      visit date_ranges_path

      click_js_link 'Download'
      click_js_link 'Download as PDF'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        export = ListExport.last
        expect(ListExportWorker).to have_queued(export.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      export = ListExport.last
      # Test the generated PDF...
      reader = PDF::Reader.new(open(export.file.url))
      reader.pages.each do |page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = page.text.gsub(/[\s\n]/, '')
        expect(text).to include 'DateRanges'
        expect(text).to include 'Weekdays'
        expect(text).to include 'Frommondaytofriday'
        expect(text).to include 'Weekends'
        expect(text).to include 'SaturdayandSunday'
      end
    end
  end
end
