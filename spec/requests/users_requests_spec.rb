require 'spec_helper'

describe "Users", :js => true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company, name: 'ABC inc.').id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  describe "user with multiple companies", :js => true  do
    it "can switch between companies" do
      another_company = FactoryGirl.create(:company, name: 'Tres Patitos S.A.')

      # Add another company to the user
      FactoryGirl.create(:company_user, company: another_company, user: @user, role: FactoryGirl.create(:role, company: another_company))
      visit root_path

      # Click on the dropdown and select the other company
      find('#company-name a.current-company-title').click
      within "ul#user-company-dropdown" do
        click_link 'Tres Patitos S.A.'
      end
      current_path.should == root_path

      within '.current-company-title' do
        page.should have_content('Tres Patitos S.A.')
        page.should_not have_content('ABC inc.')
      end

      # Click on the dropdown and select the other company
      find('#company-name a.current-company-title').click
      within "ul#user-company-dropdown" do
        click_link @company.name.to_s
      end

      current_path.should == root_path

      within '.current-company-title' do
        page.should have_content('ABC inc.')
        page.should_not have_content('Tres Patitos S.A.')
      end
    end

  end


end