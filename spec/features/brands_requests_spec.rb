require 'spec_helper'

feature "Brands", js: true do
  before do
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  feature "/brands", search: true  do
    scenario "GET index should display a list with the brands" do
      FactoryGirl.create(:brand, name: 'Brand 1', active: true, company_id: @company.id)
      FactoryGirl.create(:brand, name: 'Brand 2', active: true, company_id: @company.id)
      Sunspot.commit

      visit brands_path

      within("ul#brands-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Brand 1')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Brand 2')
        end
      end
    end

    scenario "allows the user to activate/deactivate brands" do
      FactoryGirl.create(:brand, name: 'Brand 1', active: true, company: @company)
      Sunspot.commit

      visit brands_path

      within("ul#brands-list") do
        expect(page).to have_content('Brand 1')
        hover_and_click 'li', 'Deactivate'
      end

      confirm_prompt "Are you sure you want to deactivate this brand?"

      within("ul#brands-list") do
        expect(page).to have_no_content('Brand 1')
      end

      # Make it show only the inactive elements
      filter_section('ACTIVE STATE').unicheck('Inactive')
      filter_section('ACTIVE STATE').unicheck('Active')

      within("ul#brands-list") do
        expect(page).to have_content('Brand 1')
        hover_and_click 'li', 'Activate'
        expect(page).to have_no_content('Brand 1')
      end
    end

    scenario 'allows the user to create a new brand' do
      visit brands_path

      click_js_button 'New Brand'

      within visible_modal do
        fill_in 'Name', with: 'New brand name'
        click_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'New brand name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'New brand name')
    end
  end

  feature "/brands/:brand_id", :js => true do
    scenario "GET show should display the brand details page" do
      brand = FactoryGirl.create(:brand, name: 'Brand 1', company_id: @user.current_company.id)
      visit brand_path(brand)
      expect(page).to have_selector('h2', text: 'Brand 1')
    end

    scenario 'allows the user to activate/deactivate a team' do
      brand = FactoryGirl.create(:brand, active: true, company_id: @user.current_company.id)
      visit brand_path(brand)
      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt "Are you sure you want to deactivate this brand?"

      within('.links-data') do
        click_js_link 'Activate'
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end

    scenario 'allows the user to edit the brand' do
      brand = FactoryGirl.create(:brand, company_id: @company.id)
      Sunspot.commit
      visit brand_path(brand)

      click_js_link('Edit')

      within visible_modal do
        fill_in 'Name', with: 'Edited brand name'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'Edited brand name')
    end
  end
end