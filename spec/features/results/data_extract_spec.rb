require 'rails_helper'

feature 'Data Extract Report', js: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }
  after { Warden.test_reset! }

  feature 'Create a report' do
    scenario 'user is redirected to the report build page - step 1' do
      visit results_reports_path

      click_js_button 'New Report'

      expect(page).to have_selector('#data_extract_source_chzn', count: 1)
      select_from_chosen 'Events', from: 'What type of report do you want to create?'

      click_button 'Next'

      expect(page).to have_content('Available Fields')
    end

    scenario 'navigate step' do
      visit results_reports_path

      click_js_button 'New Report'

      expect(page).to have_selector('#data_extract_source_chzn', count: 1)
      select_from_chosen 'Events', from: 'What type of report do you want to create?'

      click_button 'Next'

      expect(page).to have_content('Available Fields')

      click_button 'Next'

      expect(page).to have_selector('#collection-list-filters', count: 1)

      click_link 'SELECT FIELDS'

      expect(page).to have_content('Available Fields')

      click_link 'SELECT REPORT TYPE'

      expect(page).to have_selector('#data_extract_source_chzn', count: 1)
    end

    scenario 'create a Venues custom report and export the results' do
      place1 = create(:place, name: 'Vertigo 42',
                              reference: 'REFERENCE1',
                              place_id: 'PLACEID1',
                              formatted_address: 'Tower 42, Los Angeles, CA 23211, United States',
                              street_number: 23, route: 'Main Street',
                              city: 'Los Angeles', state: 'California', country: 'US',
                              lonlat: 'POINT(44.44 11.11)')

      place2 = create(:place, name: 'Vertigo Copy 42',
                              reference: 'REFERENCE3',
                              place_id: 'PLACEID2',
                              formatted_address: 'Tower 42 Copy, Los Angeles, CA 23211, United States',
                              street_number: 23, route: 'Main St.',
                              city: 'Los Angeles', state: 'California', country: 'US',
                              lonlat: 'POINT(44.44 11.11)',
                              merged_with_place_id: place1.id)

      create(:venue, place: place1, company: company)

      create(:venue, place: place2, company: company)

      visit results_reports_path

      click_js_button 'New Report'

      expect(page).to have_selector('#data_extract_source_chzn', count: 1)
      select_from_chosen 'Venues', from: 'What type of report do you want to create?'

      click_button 'Next'

      expect(page).to have_content('Available Fields')

      select_field('Name')
      select_field('Venue Street')

      within report_table do
        expect(page).to have_content('Vertigo 42')
        expect(page).to have_content('23 Main Street')
        expect(page).to have_no_content('Vertigo Copy 42')
        expect(page).to have_no_content('23 Main St.')
      end

      click_button 'Next'

      within report_table do
        expect(page).to have_content('Vertigo 42')
        expect(page).to have_content('23 Main Street')
        expect(page).to have_no_content('Vertigo Copy 42')
        expect(page).to have_no_content('23 Main St.')
      end

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end

      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['Name', 'Venue Street'],
        ['Vertigo 42', '23 Main Street']
      ])
      expect(ListExport.last).to_not have_rows([
        ['Vertigo Copy 42', '23 Main St.']
      ])
    end
  end

  def select_field(name)
    find('li.available-field', text: name).click
  end

  def report_table
    find('.data-extract-box')
  end
end