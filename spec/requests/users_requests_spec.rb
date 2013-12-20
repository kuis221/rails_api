require 'spec_helper'

describe "Users", :js => true do

  before do
    Warden.test_mode!
    @company = FactoryGirl.create(:company, name: 'ABC inc.')
    @user = FactoryGirl.create(:user, company_id: @company.id, role_id: FactoryGirl.create(:role, company: @company).id)
    @company = @user.companies.first
    @company_user = @user.company_users.first
    sign_in @user
  end

  describe "user with multiple companies", :js => true do
    it "can switch between companies" do
      Kpi.create_global_kpis

      another_company = FactoryGirl.create(:company, name: 'Tres Patitos S.A.')

      # Add another company to the user
      a = FactoryGirl.create(:company_user, company: another_company, user: @user, role: FactoryGirl.create(:role, company: another_company))
      visit root_path

      # Click on the dropdown and select the other company
      within('#company-name') do
        click_js_link('ABC inc.')
        find(".dropdown").click_js_link 'Tres Patitos S.A.'
      end
      current_path.should == root_path

      within '.current-company-title' do
        page.should have_content('Tres Patitos S.A.')
      end

      # Click on the dropdown and select the other company
      find('#company-name a.current-company-title').click
      within "ul#user-company-dropdown" do
        click_js_link @company.name.to_s
      end

      current_path.should == root_path

      within '.current-company-title' do
        page.should have_content('ABC inc.')
      end
    end

    describe "/users", :js => true, :search => true do
      it "allows the user to activate/deactivate users" do
        role = FactoryGirl.create(:role, name: 'TestRole', company_id: @company.id)
        user = FactoryGirl.create(:user, first_name: 'Pedro', last_name: 'Navaja', role_id: role.id, company_id: @company.id)
        Sunspot.commit
        visit company_users_path
        within("ul#users-list") do
          hover_and_click "li:nth-child(2)", 'Deactivate'
        end
        within visible_modal do
          page.should have_content('Are you sure you want to deactivate this user?')
          click_js_link("OK")
        end
        ensure_modal_was_closed
        # Make it show only the inactive elements
        filter_section('ACTIVE STATE').unicheck('Inactive')
        filter_section('ACTIVE STATE').unicheck('Active')
        within("ul#users-list") do
          page.should have_content('Pedro Navaja')
          hover_and_click "li:nth-child(1)", 'Activate'
          page.should have_no_content('Pedro Navaja')
        end
      end
    end

    describe "/users/:user_id", :js => true do
      it "GET show should display the user details page" do
        role = FactoryGirl.create(:role, name: 'TestRole', company_id: @company.id)
        user = FactoryGirl.create(:user, first_name: 'Pedro', last_name: 'Navaja', role_id: role.id, company_id: @company.id)
        company_user = user.company_users.first
        visit company_user_path(company_user)
        page.should have_selector('h2', text: 'Pedro Navaja')
        page.should have_selector('div.user-role', text: 'TestRole')
      end

      it 'allows the user to activate/deactivate a user' do
        role = FactoryGirl.create(:role, name: 'TestRole')
        user = FactoryGirl.create(:user, role_id: role.id, company_id: @company.id)
        company_user = user.company_users.first
        visit company_user_path(company_user)

        within('.links-data') do
         click_js_link('Deactivate')
       end
       visible_modal.click_js_link("OK")
       ensure_modal_was_closed
       within('.links-data') do
         click_js_link('Activate')
       end
      end

      it 'allows the user to edit another user' do
        role = FactoryGirl.create(:role, name: 'TestRole', company_id: @company.id)
        other_role = FactoryGirl.create(:role, name: 'Another Role', company_id: @company.id)
        user = FactoryGirl.create(:user, role_id: role.id, company_id: @company.id)
        company_user = user.company_users.first
        visit company_user_path(company_user)

        click_js_link('Edit')

        within("form#edit_company_user_#{company_user.id}") do
          fill_in 'First name', with: 'Pedro'
          fill_in 'Last name', with: 'Navaja'
          fill_in 'Email', with: 'pedro@navaja.com'
          select_from_chosen 'Another Role', from: 'Role'
          fill_in 'Password', with: 'Pedrito123'
          fill_in 'Password confirmation', with: 'Pedrito123'
          click_js_button 'Save'
        end

        page.should have_selector('h2', text: 'Pedro Navaja')
        page.should have_selector('div.user-role', text: 'Another Role')
      end

      it "should be able to assign areas to the user" do
        company_user = FactoryGirl.create(:company_user, company_id: @company.id)
        area = FactoryGirl.create(:area, name: 'San Francisco Area', company: @company)
        visit company_user_path(company_user)

        click_js_link 'Add Area'

        within visible_modal do
          find("#area-#{area.id}").click_js_link('Add Area')
          page.should have_no_selector("#area-#{area.id}")   # The area was removed from the available areas list
        end
        close_modal

        click_js_link 'Add Area'

        within visible_modal do
          page.should have_no_selector("#area-#{area.id}")   # The area does not longer appear on the list after it was added to the user
        end

        close_modal

        # Ensure the area now appears on the list of areas
        within '#company_user-areas-list' do
          page.should have_content('San Francisco Area')

          # Test the area removal
          hover_and_click('.hover-item', 'Remove Area')
          page.should have_no_content('San Francisco Area')
        end
      end

    end

    describe "edit profile link" do
      it 'allows the user to edit his profile' do
        visit company_user_path(@company_user)

        find('li#user_menu').click_js_link(@user.full_name).click_js_link('Edit Profile')

        within("form#edit_company_user_#{@company_user.id}") do
          fill_in 'First name', with: 'Pedro'
          fill_in 'Last name', with: 'Navaja'
          fill_in 'Email', with: 'pedro@navaja.com'
          select_from_chosen  'Costa Rica', from: 'Country'
          select_from_chosen  'Cartago', from: 'State'
          fill_in 'City', with: 'Tres Rios'
          fill_in 'Password', with: 'Pedrito123'
          fill_in 'Password confirmation', with: 'Pedrito123'
          click_js_button 'Save'
        end

        visit company_user_path(@company_user)

        @company_user.reload
        @company_user.first_name.should == 'Pedro'
        @company_user.last_name.should == 'Navaja'
        @company_user.user.unconfirmed_email.should == 'pedro@navaja.com'
        @company_user.country.should == 'CR'
        @company_user.state.should == 'C'
        @company_user.city.should == 'Tres Rios'
      end
    end

  end


end