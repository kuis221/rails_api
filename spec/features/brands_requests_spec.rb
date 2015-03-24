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
        click_js_button 'Deactivate Brand'
      end

      confirm_prompt 'Are you sure you want to deactivate this brand?'

      within('#brands-list') do
        expect(page).to have_no_content('Brand 1')
      end

      # Make it show only the inactive elements
      add_filter 'ACTIVE STATE', 'Inactive'
      remove_filter 'Active'

      expect(page).to have_content '1 brand found for: Inactive'

       within resource_item do
        expect(page).to have_content('Brand 1')
        click_js_button 'Activate Brand'
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
        click_js_button 'Deactivate Brand'
      end

      confirm_prompt 'Are you sure you want to deactivate this brand?'

      within('.links-data') do
        click_js_button 'Activate Brand'
        expect(page).to have_button 'Deactivate Brand' # test the link have changed
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

  feature 'export', search: true do
    let(:brand1) { create(:brand, name: 'Brand 1', active: true, company: company) }
    let(:brand2) { create(:brand, name: 'Brand 2', active: true, company: company) }

    before do
      # make sure brands are created before
      brand1
      brand2
      Sunspot.commit
    end

    scenario 'should be able to export as XLS' do
      visit brands_path

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['NAME', 'ACTIVE STATE'],
        ['Brand 1', 'Active'],
        ['Brand 2', 'Active']
      ])
    end

    scenario 'export list of brands as PDF' do
      visit brands_path

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
        expect(text).to include 'Brands'
        expect(text).to include 'Brand1'
        expect(text).to include 'Brand2'
      end
    end
  end
end
