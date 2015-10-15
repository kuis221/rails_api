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

  feature 'User managment', js: true, search: true do
    let(:role) { create(:role, name: 'TestRole', company_id: company.id) }
    scenario 'allows the user to activate/deactivate users' do
      create(:user, first_name: 'Pedro', last_name: 'Navaja', role_id: role.id, company_id: company.id)
      Sunspot.commit
      visit company_users_path
      within resource_item list: '#users-list' do
        click_js_button 'Deactivate User'
      end

      confirm_prompt 'Are you sure you want to deactivate this user?'

      # Make it show only the inactive elements
      remove_filter 'Active'
      add_filter 'ACTIVE STATE', 'Inactive'

      expect(page).to have_content '1 user found for: Inactive'

      within resource_item list: '#users-list' do
        expect(page).to have_content('Pedro Navaja')
        click_js_button 'Activate User'
      end

      expect(page).to have_no_content('Pedro Navaja')
    end

    scenario 'allows the user to deactivate invited users' do
      create(:invited_user, first_name: 'Pedro', last_name: 'Navaja', role_id: role.id, company_id: company.id)
      Sunspot.commit
      visit company_users_path

      # Make it show only the invited elements
      remove_filter 'Active'
      add_filter 'ACTIVE STATE', 'Invited'

      within resource_item list: '#users-list' do
        expect(page).to have_button('Deactivate User')
        click_js_button 'Deactivate User'
      end

      confirm_prompt 'Are you sure you want to deactivate this user?'

      wait_for_ajax

      within resource_item list: '#users-list' do
        expect(page).to have_no_button('Deactivate User')
      end

      remove_filter 'Invited'
      add_filter 'ACTIVE STATE', 'Invited'
      expect(page).not_to have_content('Pedro Navaja')

    end

    scenario 'allow a user to invite users' do
      create(:non_admin_role, name: 'TestRole', company_id: company.id)
      visit company_users_path

      click_js_button 'Invite user'

      within visible_modal do
        fill_in 'First name', with: 'Fulanito'
        fill_in 'Last name', with: 'de Tal'
        fill_in 'Email', with: 'fulanito@detal.com'
        select_from_chosen 'TestRole', from: 'Role'
        click_js_button 'Send request'
      end
      ensure_modal_was_closed

      # Deselect "Active" and select "Invited"
      remove_filter 'Active'
      add_filter 'ACTIVE STATE', 'Invited'

      expect(page).to have_content '1 user found for: Invited'

      within resource_item do
        expect(page).to have_content 'Fulanito de Tal'
        expect(page).to have_content 'TestRole'
      end
    end

    scenario 'allows the user to resend invitations to invited users' do
      invited_user = create(:invited_user, first_name: 'Pedro', last_name: 'Navaja', role_id: role.id, company_id: company.id)
      Sunspot.commit
      visit company_users_path

      # Make it show only the invited elements
      remove_filter 'Active'
      add_filter 'ACTIVE STATE', 'Invited'

      within resource_item list: '#users-list' do
        expect(page).to have_button('Resend Invitation')
        click_js_button 'Resend Invitation'
      end

      confirm_prompt 'Are you sure you want to resend the invitation to this user?'
      wait_for_ajax

      the_user = User.last

      expect(the_user.first_name).to eq(invited_user.first_name)
      expect(the_user.last_name).to eq(invited_user.last_name)
      # Invitation token should not change
      expect(the_user.invitation_token).to eq(invited_user.invitation_token)
    end

    it_behaves_like 'a list that allow saving custom filters' do

      before do
        create(:campaign, name: 'Campaign 1', company: company)
        create(:campaign, name: 'Campaign 2', company: company)
        create(:team, name: 'Team 1', company: company)
      end

      let(:list_url) { company_users_path }

      let(:filters) do
        [{ section: 'CAMPAIGNS', item: 'Campaign 1' },
         { section: 'CAMPAIGNS', item: 'Campaign 2' },
         { section: 'TEAMS', item: 'Team 1' },
         { section: 'ACTIVE STATE', item: 'Inactive' }]
      end
    end
  end

  feature 'User details page', js: true do
    scenario 'user details are displayed' do
      role = create(:role, name: 'TestRole', company_id: company.id)
      user = create(:user, first_name: 'Pedro', last_name: 'Navaja', role_id: role.id, company_id: company.id)
      company_user = user.company_users.first
      visit company_user_path(company_user)
      expect(page).to have_selector('h2', text: 'Pedro Navaja')
      expect(page).to have_selector('div.user-role', text: 'TestRole')
    end

    scenario 'a user can activate/deactivate a user' do
      role = create(:role, name: 'TestRole')
      user = create(:user, role_id: role.id, company_id: company.id)
      company_user = user.company_users.first
      visit company_user_path(company_user)

      within('.edition-links') do
        click_js_button 'Deactivate User'
      end

      confirm_prompt 'Are you sure you want to deactivate this user?'

      within('.edition-links') do
        click_js_button 'Activate User'
        expect(page).to have_button('Deactivate User') # test the link have changed
      end
    end

    scenario 'allows the user to edit another user' do
      role = create(:non_admin_role, name: 'TestRole', company_id: company.id)
      create(:non_admin_role, name: 'Another Role', company_id: company.id)
      user = create(:user, first_name: 'Juanito', last_name: 'Mora', role_id: role.id, company_id: company.id)
      company_user = user.company_users.first
      visit company_user_path(company_user)

      expect(page).to have_content('Juanito Mora')

      within('.edition-links') { click_js_button 'Edit Profile Data' }

      within "form#edit_company_user_#{company_user.id}" do
        fill_in 'First name', with: 'Pedro'
        fill_in 'Last name', with: 'Navaja'
        fill_in 'Email', with: 'pedro@navaja.com'
        select_from_chosen 'Another Role', from: 'Role'
        fill_in 'Password (optional)', with: 'Pedrito123'
        fill_in 'Password confirmation', with: 'Pedrito123'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_no_content('Juanito Mora')
      expect(page).to have_selector('h2', text: 'Pedro Navaja')
      expect(page).to have_selector('div.user-role', text: 'Another Role')
    end

    scenario 'should validate who is not present the role admin' do
      role = create(:role, name: 'Test admin role', company: company)
      role2 = create(:non_admin_role, name: 'Test not admin role', company: company)
      user = create(:user, first_name: 'Juanito', last_name: 'Mora', role_id: role2.id, company_id: company.id)
      company_user = user.company_users.first
      visit company_user_path(company_user)

      expect(page).to have_content('Juanito Mora')

      within('.edition-links') { click_js_button 'Edit Profile Data' }

      expect(page).to_not have_content('Test admin role')
      expect(page).to have_content('Test not admin role')
    end

    scenario 'allows to assign areas to the user' do
      other_company_user = create(:company_user, company_id: company.id)
      area = create(:area, name: 'San Francisco Area', company: company)
      create(:area, name: 'Los Angeles Area', company: company)
      visit company_user_path(other_company_user)

      expect(page).to have_content 'No Places have been assigned to this user.'

      click_js_button 'Add Place'

      within visible_modal do
        fill_in 'place-search-box', with: 'San'
        expect(page).to have_content('San Francisco Area')
        expect(page).to have_no_content('Los Angeles Area')
        within resource_item area do
          click_js_link 'Add Area'
        end
        expect(page).to have_no_selector("#area-#{area.id}") # The area was removed from the available areas list
      end
      close_modal

      expect(page).to_not have_content 'No Places have been assigned to this user.'

      # Re-open the modal to make sure it's not added again to the list
      click_js_button 'Add Place'
      within visible_modal do
        fill_in 'place-search-box', with: 'San'
        expect(page).to_not have_content('San Francisco Area')
        expect(page).to have_no_content('Los Angeles Area')
      end
      close_modal

      # Ensure the area now appears on the list of areas
      expect(page).to have_content('San Francisco Area')

      # Test the area removal
      within '#company_user-areas-list' do
        hover_and_click('.hover-item', 'Remove Area')
      end
      expect(page).to_not have_content('San Francisco Area')

      expect(page).to have_content 'No Places have been assigned to this user.'
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

    scenario 'should be able to assign campaign to the user' do
      other_company_user = create(:company_user, company_id: company.id)
      brand_portfolio = create(:brand_portfolio, name: 'Guisqui', company: company)

      campaign = create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: company)
      campaign2 = create(:campaign, name: 'Centenario FY12', description: 'ron Centenario test campaign', company: company)

      brand_portfolio.campaigns << campaign
      brand_portfolio.campaigns << campaign2

      visit company_user_path(other_company_user)

      find("#btn-add-campaign-BrandPortfolio-#{brand_portfolio.id}").click

      within visible_modal do
        fill_in 'campaign-search-box', with: 'Caci'
        expect(page).to have_content('Cacique FY13')
        expect(page).to have_no_content('Centenario FY12')
        within resource_item campaign do
          click_js_link 'Add Campaign'
        end
        expect(page).to have_no_selector("#campaign-#{campaign.id}") # The campaign was removed from the available campaigns list
      end
      close_modal

      expect(page).to have_content('Cacique FY13')
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

      within('.edition-links') { click_js_button 'Edit Profile Data' }

      within visible_modal do
        fill_in 'First name', with: 'Pedro'
        fill_in 'Last name', with: 'Navaja'
        fill_in 'Email', with: 'pedro@navaja.com'
        select_from_chosen 'Costa Rica', from: 'Country'
        select_from_chosen 'Cartago', from: 'State'
        fill_in 'City', with: 'Tres Rios'
        fill_in 'Password (optional)', with: 'Pedrito123'
        fill_in 'Password confirmation', with: 'Pedrito123'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      visit company_user_path(company_user)

      company_user.reload
      expect(company_user.first_name).to eq('Pedro')
      expect(company_user.last_name).to eq('Navaja')
      expect(company_user.user.unconfirmed_email).to eq('pedro@navaja.com')
      expect(company_user.country).to eq('CR')
      expect(company_user.state).to eq('C')
      expect(company_user.city).to eq('Tres Rios')
    end

    scenario 'user can modify his email address' do
      visit company_user_path(company_user)

      within('.edition-links') { click_js_button 'Edit Profile Data' }

      within visible_modal do
        fill_in 'Email', with: 'pedro@navaja.com'
        click_js_button 'Save'
      end
      expect(page).to have_content(
        'A confirmation email was sent to pedro@navaja.com. '\
        'Your email will not be changed until you complete this step.'
      )

      within('.edition-links') { click_js_button 'Edit Profile Data' }
      within visible_modal do
        expect(page).to have_content(
          'Check your (pedro@navaja.com) to confirm your new address. '\
          'Until you confirm, you will continue to use your current email address.'
        )
      end
    end

    scenario 'user can cancel his email address change before confirmation' do
      visit company_user_path(company_user)

      within('.edition-links') { click_js_button 'Edit Profile Data' }

      confirmation_message = 'A confirmation email was sent to pedro@navaja.com. '\
        'Your email will not be changed until you complete this step.'

      within visible_modal do
        fill_in 'Email', with: 'pedro@navaja.com'
        click_js_button 'Save'
      end

      expect(page).to have_content confirmation_message

      within('.edition-links') { click_js_button 'Edit Profile Data' }
      within visible_modal do
        click_js_link 'Cancel this change'
      end
      close_modal

      expect(page).not_to have_content confirmation_message
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
    let(:user1) do
      create(:user, first_name: 'Pablo', last_name: 'Baltodano', email: 'email@hotmail.com',
                          city: 'Los Angeles', state: 'CA', country: 'US', company: company, role_id: role.id)
    end
    let(:user2) do
      create(:user, first_name: 'Juanito', last_name: 'Bazooka', email: 'bazooka@gmail.com',
                          city: 'New York', state: 'NY', country: 'US', company: company, role_id: role.id)
    end

    before do
      # make sure users are created before
      user1
      user2
      Sunspot.commit
    end

    scenario 'should be able to export as CSV' do
      visit company_users_path

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['FIRST NAME', 'LAST NAME', 'EMAIL', 'PHONE NUMBER', 'ROLE', 'ADDRESS 1', 'ADDRESS 2',
         'CITY', 'STATE', 'ZIP CODE', 'COUNTRY', 'TIME ZONE', 'LAST LOGIN', 'ACTIVE STATE'],
        ['Juanito', 'Bazooka', 'bazooka@gmail.com', '+1000000000', 'TestRole', 'Street Address 123',
         'Unit Number 456', 'New York', 'NY', '90210', 'United States', 'Pacific Time (US & Canada)', nil, 'Active'],
        ['Pablo', 'Baltodano', 'email@hotmail.com', '+1000000000', 'TestRole', 'Street Address 123',
         'Unit Number 456', 'Los Angeles', 'CA', '90210', 'United States', 'Pacific Time (US & Canada)', nil, 'Active'],
        ['Test', 'User', user.email, '+1000000000', Role.first.name, 'Street Address 123',
         'Unit Number 456', 'Curridabat', 'SJ', '90210', 'Costa Rica', 'Pacific Time (US & Canada)', company_user.last_activity_at.to_s, 'Active']
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
