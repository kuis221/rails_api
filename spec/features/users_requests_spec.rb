require 'rails_helper'

feature 'Users', js: true do
  let(:company) { create(:company, name: 'ABC inc.') }
  let(:user) { create(:user, company_id: company.id, role_id: create(:role, company: company).id) }
  let(:company_user) { user.company_users.first }

  before do
    Warden.test_mode!
    sign_in user
  end

  feature 'user with multiple companies', js: true do
    scenario 'can switch between companies' do
      Kpi.create_global_kpis

      another_company = create(:company, name: 'Tres Patitos S.A.')

      # Add another company to the user
      create(:company_user,
             company: another_company, user: user,
             role: create(:role, company: another_company))
      visit root_path

      # Click on the dropdown and select the other company
      within('#company-name') do
        click_link('ABC inc.')
        find('.dropdown').click_link 'Tres Patitos S.A.'
      end
      expect(current_path).to eq(root_path)

      within '.current-company-title' do
        expect(page).to have_content('Tres Patitos S.A.')
      end

      # Click on the dropdown and select the other company
      find('#company-name a.current-company-title').click
      within 'ul#user-company-dropdown' do
        click_link company.name.to_s
      end

      expect(current_path).to eq(root_path)

      within '.current-company-title' do
        expect(page).to have_content('ABC inc.')
      end
    end
  end

  feature '/users', js: true, search: true do
    scenario 'allows the user to activate/deactivate users' do
      role = create(:role, name: 'TestRole', company_id: company.id)
      create(:user, first_name: 'Pedro', last_name: 'Navaja', role_id: role.id, company_id: company.id)
      Sunspot.commit
      visit company_users_path
      within resource_item list: '#users-list' do
        click_js_button 'Deactivate User'
      end

      confirm_prompt 'Are you sure you want to deactivate this user?'

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')
      within resource_item list: '#users-list' do
        expect(page).to have_content('Pedro Navaja')
        click_js_button 'Activate User'
      end

      expect(page).to have_no_content('Pedro Navaja')
    end
  end

  feature '/users/:user_id', js: true do
    scenario 'GET show should display the user details page' do
      role = create(:role, name: 'TestRole', company_id: company.id)
      user = create(:user, first_name: 'Pedro', last_name: 'Navaja', role_id: role.id, company_id: company.id)
      company_user = user.company_users.first
      visit company_user_path(company_user)
      expect(page).to have_selector('h2', text: 'Pedro Navaja')
      expect(page).to have_selector('div.user-role', text: 'TestRole')
    end

    scenario 'allows the user to activate/deactivate a user' do
      role = create(:role, name: 'TestRole')
      user = create(:user, role_id: role.id, company_id: company.id)
      company_user = user.company_users.first
      visit company_user_path(company_user)

      within('.profile-data') do
        click_js_button 'Deactivate User'
      end

      confirm_prompt 'Are you sure you want to deactivate this user?'

      within('.profile-data') do
        click_js_button 'Activate User'
        expect(page).to have_button('Deactivate User') # test the link have changed
      end
    end

    scenario 'allows the user to edit another user' do
      role = create(:role, name: 'TestRole', company_id: company.id)
      create(:role, name: 'Another Role', company_id: company.id)
      user = create(:user, first_name: 'Juanito', last_name: 'Mora', role_id: role.id, company_id: company.id)
      company_user = user.company_users.first
      visit company_user_path(company_user)

      expect(page).to have_content('Juanito Mora')

      within('.profile-data') { click_js_button 'Edit Profile Data' }

      within "form#edit_company_user_#{company_user.id}" do
        fill_in 'First name', with: 'Pedro'
        fill_in 'Last name', with: 'Navaja'
        fill_in 'Email', with: 'pedro@navaja.com'
        select_from_chosen 'Another Role', from: 'Role'
        fill_in 'Password', with: 'Pedrito123'
        fill_in 'Password confirmation', with: 'Pedrito123'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_no_content('Juanito Mora')
      expect(page).to have_selector('h2', text: 'Pedro Navaja')
      expect(page).to have_selector('div.user-role', text: 'Another Role')
    end

    scenario 'should be able to assign areas to the user' do
      other_company_user = create(:company_user, company_id: company.id)
      area = create(:area, name: 'San Francisco Area', company: company)
      area2 = create(:area, name: 'Los Angeles Area', company: company)
      visit company_user_path(other_company_user)

      click_js_link 'Add Area'

      within visible_modal do
        fill_in 'place-search-box', with: 'San'
        expect(page).to have_selector("#area-#{area.id}")
        expect(page).to have_no_selector("#area-#{area2.id}")
        expect(page).to have_content('San Francisco Area')
        expect(page).to have_no_content('Los Angeles Area')
        within resource_item area do
          click_js_link('Add Area')
        end
        expect(page).to have_no_selector("#area-#{area.id}") # The area was removed from the available areas list
      end
      close_modal

      # Re-open the modal to make sure it's not added again to the list
      click_js_link 'Add Area'
      within visible_modal do
        expect(page).to have_no_selector("#area-#{area.id}") # The area does not longer appear on the list after it was added to the user
        expect(page).to have_selector("#area-#{area2.id}")
      end
      close_modal

      # Ensure the area now appears on the list of areas
      within '#company_user-areas-list' do
        expect(page).to have_content('San Francisco Area')

        # Test the area removal
        hover_and_click('.hover-item', 'Remove Area')
        expect(page).to have_no_content('San Francisco Area')
      end
    end

    scenario 'should be able to assign brand portfolios to the user' do
      other_company_user = create(:company_user, company_id: company.id)
      brand_portfolio = create(:brand_portfolio, name: 'Guisqui', company: company)
      create(:brand_portfolio, name: 'Guaro', company: company)
      visit company_user_path(other_company_user)

      within "#campaigns-toggle-BrandPortfolio-#{brand_portfolio.id}" do
        click_js_link 'Toggle ON'
        expect(page).not_to have_link('Toggle ON')
        expect(page).to have_link('Toggle OFF')
      end
      wait_for_ajax
      expect(other_company_user.reload.brand_portfolios.to_a).to eql [brand_portfolio]

      visit company_user_path(other_company_user)

      within "#campaigns-toggle-BrandPortfolio-#{brand_portfolio.id}" do
        click_js_link 'Toggle OFF'
        expect(page).not_to have_link('Toggle OFF')
        expect(page).to have_link('Toggle ON')
      end
      wait_for_ajax
      expect(other_company_user.reload.brand_portfolios.to_a).to be_empty
    end

    scenario 'should be able to assign brands to the user' do
      other_company_user = create(:company_user, company_id: company.id)
      brand = create(:brand, name: 'Guisqui Rojo', company: company)
      create(:brand, name: 'Cacique', company: company)
      visit company_user_path(other_company_user)

      within "#campaigns-toggle-Brand-#{brand.id}" do
        click_js_link 'Toggle ON'
        expect(page).not_to have_link('Toggle ON')
        expect(page).to have_link('Toggle OFF')
      end
      wait_for_ajax
      expect(other_company_user.reload.brands.to_a).to eql [brand]

      visit company_user_path(other_company_user)

      within "#campaigns-toggle-Brand-#{brand.id}" do
        click_js_link 'Toggle OFF'
        expect(page).not_to have_link('Toggle OFF')
        expect(page).to have_link('Toggle ON')
      end
      wait_for_ajax
      expect(other_company_user.reload.brands.to_a).to be_empty
    end
  end

  feature 'edit profile link' do
    scenario 'allows the user to edit his profile' do
      visit root_path

      within 'li#user_menu' do
        click_js_link user.full_name
        click_js_link 'View Profile'
      end

      expect(page).to have_selector('h2', text: company_user.full_name)
      expect(current_path).to eql '/users/profile'

      within('.profile-data') { click_js_button 'Edit Profile Data' }

      within visible_modal do
        fill_in 'First name', with: 'Pedro'
        fill_in 'Last name', with: 'Navaja'
        fill_in 'Email', with: 'pedro@navaja.com'
        select_from_chosen 'Costa Rica', from: 'Country'
        select_from_chosen 'Cartago', from: 'State'
        fill_in 'City', with: 'Tres Rios'
        fill_in 'Password', with: 'Pedrito123'
        fill_in 'Password confirmation', with: 'Pedrito123'
        click_js_button 'Save'
      end

      visit company_user_path(company_user)

      company_user.reload
      expect(company_user.first_name).to eq('Pedro')
      expect(company_user.last_name).to eq('Navaja')
      expect(company_user.user.unconfirmed_email).to eq('pedro@navaja.com')
      expect(company_user.country).to eq('CR')
      expect(company_user.state).to eq('C')
      expect(company_user.city).to eq('Tres Rios')
    end

    scenario 'allows the user to edit his communication preferences' do
      visit company_user_path(company_user)

      within 'li#user_menu' do
        click_js_link(user.full_name)
        click_js_link('View Profile')
      end

      click_js_link 'Edit Communication Preferences'

      within("form#edit_company_user_#{company_user.id}") do
        find('#notification_settings_event_recap_due_app').trigger('click')
        find('#notification_settings_event_recap_due_sms').trigger('click')
        find('#notification_settings_event_recap_due_email').trigger('click')
        click_js_button 'Save'
      end

      wait_for_ajax

      company_user.reload
      expect(company_user.notifications_settings).to include('event_recap_due_sms', 'event_recap_due_email')
      expect(company_user.notifications_settings).to_not include('event_recap_due_app')
    end
  end

  feature 'export', search: true do
    let(:role) { create(:role, name: 'TestRole', company: company) }
    let(:user1) { create(:user, first_name: 'Pablo', last_name: 'Baltodano', email: 'email@hotmail.com',
                          city: 'Los Angeles', state: 'CA', country: 'US', company: company, role_id: role.id) }
    let(:user2) { create(:user, first_name: 'Juanito', last_name: 'Bazooka', email: 'bazooka@gmail.com',
                          city: 'New York', state: 'NY', country: 'US', company: company, role_id: role.id) }

    before do
      # make sure users are created before
      user1
      user2
      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit company_users_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['FULL NAME', 'ROLE', 'CITY', 'COUNTRY', 'EMAIL', 'LAST ACTIVITY'],
        ['Juanito Bazooka', 'TestRole', 'New York, NY', 'United States', 'bazooka@gmail.com', nil],
        ['Pablo Baltodano', 'TestRole', 'Los Angeles, CA', 'United States', 'email@hotmail.com', nil],
        ['Test User', Role.first.name, 'Curridabat, SJ', 'Costa Rica', user.email, 'about 0 minutes ago']
      ])
    end

    scenario 'should be able to export as PDF' do
      visit company_users_path

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
        expect(text).to include 'Users'
        expect(text).to include 'JuanitoBazooka'
        expect(text).to include 'NewYork,NY'
        expect(text).to include 'bazooka@gmail.com'
        expect(text).to include 'TestRole'
        expect(text).to include 'UnitedStates'
        expect(text).to include 'PabloBaltodano'
        expect(text).to include 'LosAngeles,CA'
        expect(text).to include 'email@hotmail.com'
        expect(text).to include 'TestUser'
        expect(text).to include 'Curridabat,SJ'
        expect(text).to include user.email
      end
    end
  end
end
