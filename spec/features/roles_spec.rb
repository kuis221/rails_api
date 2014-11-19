require 'rails_helper'

feature 'Roles', js: true do
  let(:company) { create(:company) }
  let(:user) { create(:user, company_id: company.id, role_id: create(:role, name: 'Role 1', company: company).id) }
  let(:company_user) { user.company_users.first }

  before { sign_in user }
  after { Warden.test_reset! }

  feature '/roles', search: true do
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
        click_js_button 'Deactivate Role'
      end

      confirm_prompt 'Costa Rica Role users can no longer login if you deactivate that role. Would you like to continue?'

      within('#roles-list') do
        expect(page).to have_no_content('Costa Rica Role')
      end

      # Make it show only the inactive elements
      add_filter 'ACTIVE STATE', 'Inactive'
      remove_filter 'Active'

      expect(page).to have_content '1 role found for: Inactive'

      within resource_item 1 do
        expect(page).to have_content('Costa Rica Role')
        click_js_button 'Activate Role'
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
      role = create(:role, name: 'Admin', active: true, company_id: company.id)
      visit role_path(role)
      within('.links-data') do
        click_js_button 'Deactivate Role'
      end

      confirm_prompt 'Admin users can no longer login if you deactivate that role. Would you like to continue?'

      within('.links-data') do
        click_js_button 'Activate Role'
        expect(page).to have_button 'Deactivate Role' # test the link have changed
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

  feature 'custom filters', search: true do
    let(:role1) { create(:role, name: 'Costa Rica Role', description: 'El grupo de ticos', active: true, company: company) }
    let(:role2) { create(:role, name: 'Buenos Aires Role', description: 'The guys from BAs', active: false, company: company) }

    before do
      # make sure roles are created before
      role1
      role2
      Sunspot.commit
    end

    scenario 'allows to create a new custom filter' do
      visit roles_path

      filter_section('ACTIVE STATE').unicheck('Active')
      filter_section('ACTIVE STATE').unicheck('Inactive')

      click_button 'Save'

      within visible_modal do
        fill_in('Filter name', with: 'My Custom Filter')
        expect do
          click_button 'Save'
          wait_for_ajax
        end.to change(CustomFilter, :count).by(1)

        custom_filter = CustomFilter.last
        expect(custom_filter.owner).to eq(company_user)
        expect(custom_filter.name).to eq('My Custom Filter')
        expect(custom_filter.apply_to).to eq('roles')
        expect(custom_filter.filters).to eq('status%5B%5D=Inactive')
      end
      ensure_modal_was_closed

      within '.form-facet-filters' do
        expect(page).to have_content('My Custom Filter')
      end
    end

    scenario 'allows to apply custom filters' do
      create(:custom_filter,
             owner: company_user, name: 'Custom Filter 1', apply_to: 'roles',
             filters: 'status%5B%5D=Active')
      create(:custom_filter,
             owner: company_user, name: 'Custom Filter 2', apply_to: 'roles',
             filters: 'status%5B%5D=Inactive')

      visit roles_path

      within roles_list do
        expect(page).to have_content('Costa Rica Role')
        expect(page).to_not have_content('Buenos Aires Role')
      end

      # Using Custom Filter 1
      filter_section('SAVED FILTERS').unicheck('Custom Filter 1')

      within roles_list do
        expect(page).to have_content('Costa Rica Role')
        expect(page).to_not have_content('Buenos Aires Role')
      end

      within '.form-facet-filters' do
        expect(find_field('Active')['checked']).to be_truthy
        expect(find_field('Inactive')['checked']).to be_falsey
        expect(find_field('Custom Filter 1')['checked']).to be_truthy
        expect(find_field('Custom Filter 2')['checked']).to be_falsey
      end

      # Using Custom Filter 2 should update results and checked/unchecked checkboxes
      filter_section('SAVED FILTERS').unicheck('Custom Filter 2')

      within roles_list do
        expect(page).to_not have_content('Costa Rica Role')
        expect(page).to have_content('Buenos Aires Role')
      end

      within '.form-facet-filters' do
        expect(find_field('Active')['checked']).to be_falsey
        expect(find_field('Inactive')['checked']).to be_truthy
        expect(find_field('Custom Filter 1')['checked']).to be_falsey
        expect(find_field('Custom Filter 2')['checked']).to be_truthy
      end
    end
  end

  feature 'export', search: true do
    let(:role1) { create(:role, name: 'Costa Rica Role', description: 'El grupo de ticos', active: true, company: company) }
    let(:role2) { create(:role, name: 'Buenos Aires Role', description: 'The guys from BAs', active: true, company: company) }

    before do
      # make sure roles are created before
      role1
      role2
      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit roles_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE'],
        ['Buenos Aires Role', 'The guys from BAs', 'Active'],
        ['Costa Rica Role', 'El grupo de ticos', 'Active'],
        ['Role 1', 'Test Role description', 'Active']
      ])
    end

    scenario 'should be able to export as PDF' do
      visit roles_path

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
        expect(text).to include 'Roles'
        expect(text).to include 'BuenosAiresRole'
        expect(text).to include 'TheguysfromBAs'
        expect(text).to include 'CostaRicaRole'
        expect(text).to include 'Elgrupodeticos'
        expect(text).to include 'Role1'
        expect(text).to include 'TestRoledescription'
      end
    end
  end

  def roles_list
    '#roles-list'
  end
end
