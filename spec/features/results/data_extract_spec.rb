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

      expect(page).to have_selector('#data_source_id_chzn', count: 1)
      select_from_chosen 'Events', from: '1. Choose a data source for your report'
      
      click_button 'Next'

      expect(page).to have_content('Available Fields')
    end

    scenario 'user no select data source - step 1' do
      visit results_reports_path

      click_js_button 'New Report'

      expect(page).to have_selector('#data_source_id_chzn', count: 1)
      
      click_button 'Next'

      expect(page).to_not have_content('Available Fields')
    end
  end
end