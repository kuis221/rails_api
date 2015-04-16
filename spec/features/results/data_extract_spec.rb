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
      select_from_chosen 'Events', from: 'Choose a data source for your report'
      
      click_button 'Next'

      expect(page).to have_content('Available Fields')
    end

    scenario 'navigate step' do
      visit results_reports_path

      click_js_button 'New Report'

      expect(page).to have_selector('#data_extract_source_chzn', count: 1)
      select_from_chosen 'Events', from: 'Choose a data source for your report'
      
      click_button 'Next'

      expect(page).to have_content('Available Fields')

      click_button 'Next'

      expect(page).to have_selector('#collection-list-filters', count: 1)

      click_link 'CONFIGURE'

      expect(page).to have_content('Available Fields')

      click_link 'SELECT SOURCES'

      expect(page).to have_selector('#data_extract_source_chzn', count: 1)
    end
  end
end