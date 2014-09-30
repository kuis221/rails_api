require 'rails_helper'

feature 'Roles', js: true do
  let(:company) { create(:company) }
  let(:user) { create(:user, company_id: company.id, role_id: create(:role, company: company).id) }

  before { sign_in user }
  after { Warden.test_reset! }

  feature '/roles', search: true  do
    scenario 'GET index should display a list with the roles' do
      create(:role, name: 'Costa Rica Role',
        description: 'el grupo de ticos', active: true, company_id: company.id)
      create(:role, name: 'Buenos Aires Role',
        description: 'the guys from BAs', active: true, company_id: company.id)
      Sunspot.commit

      visit roles_path

      # First Row
      within resource_item 1 do
        expect(page).to have_content('Buenos Aires Role')
        expect(page).to have_content('the guys from BAs')
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content('Costa Rica Role')
        expect(page).to have_content('el grupo de ticos')
      end
    end

    scenario 'allows the user to activate/deactivate roles' do
      create(:role, name: 'Costa Rica Role', description: 'el grupo de ticos', active: true, company: company)
      Sunspot.commit

      visit roles_path

      within resource_item 1 do
        expect(page).to have_content('Costa Rica Role')
        click_js_link 'Deactivate'
      end

      confirm_prompt 'Are you sure you want to deactivate this role?'

      within('#roles-list') do
        expect(page).to have_no_content('Costa Rica Role')
      end

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within resource_item 1 do
        expect(page).to have_content('Costa Rica Role')
        click_js_link 'Activate'
      end
      expect(page).to have_no_content('Costa Rica Role')
    end

    scenario 'allows the user to create a new role' do
      visit roles_path

      click_js_button 'New Role'

      within visible_modal do
        fill_in 'Name', with: 'new role name'
        fill_in 'Description', with: 'new role description'
        click_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new role name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'new role name')
      expect(page).to have_selector('div.description-data', text: 'new role description')
    end
  end

  feature '/roles/:role_id', js: true do
    scenario 'GET show should display the role details page' do
      role = create(:role, name: 'Some Role Name', description: 'a role description', company_id: company.id)
      visit role_path(role)
      expect(page).to have_selector('h2', text: 'Some Role Name')
      expect(page).to have_selector('div.description-data', text: 'a role description')
    end

    scenario 'allows the user to activate/deactivate a role' do
      role = create(:role, active: true, company_id: company.id)
      visit role_path(role)
      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this role?'

      within('.links-data') do
        click_js_link 'Activate'
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end

    scenario 'allows the user to edit the role' do
      role = create(:role, company_id: company.id)
      Sunspot.commit
      visit role_path(role)

      within('.links-data') { click_js_button 'Edit Role' }

      within visible_modal do
        fill_in 'Name', with: 'edited role name'
        fill_in 'Description', with: 'edited role description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'edited role name')
      expect(page).to have_selector('div.description-data', text: 'edited role description')
    end
  end

end
