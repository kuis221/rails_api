require 'rails_helper'

feature 'Brands', js: true do
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

  feature '/brands', search: true  do
    scenario 'GET index should display a list with the brands' do
      create(:brand, name: 'Brand 1', active: true, company_id: company.id)
      create(:brand, name: 'Brand 2', active: true, company_id: company.id)
      Sunspot.commit

      visit brands_path

      # First Row
      within resource_item 1, list: '#brands-list' do
        expect(page).to have_content('Brand 1')
      end
      # Second Row
      within resource_item 2, list: '#brands-list' do
        expect(page).to have_content('Brand 2')
      end
    end

    scenario 'allows the user to activate/deactivate brands' do
      create(:brand, name: 'Brand 1', active: true, company: company)
      Sunspot.commit

      visit brands_path

      within resource_item do
        expect(page).to have_content('Brand 1')
        click_js_link 'Deactivate'
      end

      confirm_prompt 'Are you sure you want to deactivate this brand?'

      within('#brands-list') do
        expect(page).to have_no_content('Brand 1')
      end

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

       within resource_item do
        expect(page).to have_content('Brand 1')
        click_js_link 'Activate'
      end
      expect(page).to have_no_content('Brand 1')
    end

    scenario 'allows the user to create a new brand' do
      visit brands_path

      click_js_button 'New Brand'

      within visible_modal do
        fill_in 'Name', with: 'New brand name'
        select2_add_tag 'Marques list', 'Marque 1'
        select2_add_tag 'Marques list', 'Marque 2'

        click_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'New brand name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'New brand name')
      expect(page).to have_selector('div.marques-data', text: 'Marque(s): Marque 1, Marque 2')
    end
  end

  feature '/brands/:brand_id', js: true do
    scenario 'GET show should display the brand details page' do
      brand = create(:brand,
                     name: 'Brand 1', marques_list: 'Marque 1,Marque 2',
                     company_id: user.current_company.id)
      visit brand_path(brand)
      expect(page).to have_selector('h2', text: 'Brand 1')
      expect(page).to have_selector('div.marques-data', text: 'Marque(s): Marque 1, Marque 2')
    end

    scenario 'allows the user to activate/deactivate a team' do
      brand = create(:brand, active: true, company_id: user.current_company.id)
      visit brand_path(brand)
      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this brand?'

      within('.links-data') do
        click_js_link 'Activate'
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end

    scenario 'allows the user to edit the brand' do
      brand = create(:brand, company_id: company.id)
      Sunspot.commit
      visit brand_path(brand)

      within('.links-data') { click_js_button 'Edit Brand' }

      within visible_modal do
        fill_in 'Name', with: 'Edited brand name'
        select2_add_tag 'Marques list', 'Marque 1'

        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'Edited brand name')
      expect(page).to have_selector('div.marques-data', text: 'Marque(s): Marque 1')
    end

    scenario 'allows the user to remove a marquee' do
      brand = create(:brand, name: 'Brand 1', marques_list: 'Marque 1,Marque 2', company_id: company.id)
      Sunspot.commit
      visit brand_path(brand)

      within('.links-data') { click_js_button 'Edit Brand' }

      within visible_modal do
        select2_remove_tag('Marque 1')
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'Brand 1')
      expect(page).to have_selector('div.marques-data', text: 'Marque(s): Marque 2')
    end
  end
end
