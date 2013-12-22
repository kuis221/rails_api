require 'spec_helper'

feature "Campaigns", js: true, search: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  feature "/campaigns" do
    feature "GET index" do
      scenario "should display a table with the campaigns" do
        campaigns = [
          FactoryGirl.create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: @company),
          FactoryGirl.create(:campaign, name: 'Centenario FY12', description: 'ron Centenario test campaign', company: @company)
        ]
        Sunspot.commit
        visit campaigns_path

        within("ul#campaigns-list") do
          # First Row
          within("li:nth-child(1)") do
            expect(page).to have_content(campaigns[0].name)
            expect(page).to have_content(campaigns[0].description)
          end
          # Second Row
          within("li:nth-child(2)") do
            expect(page).to have_content(campaigns[1].name)
            expect(page).to have_content(campaigns[1].description)
          end
        end
        wait_for_ajax
      end

      scenario "should allow user to deactivate campaigns" do
        FactoryGirl.create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: @company)
        Sunspot.commit
        visit campaigns_path

        expect(page).to have_content('Cacique FY13')
        within("ul#campaigns-list li:nth-child(1)") do
          click_link('Deactivate')
        end

        confirm_prompt "Are you sure you want to deactivate this campaign?"

        expect(page).to have_no_content('Cacique FY13')
        wait_for_ajax
      end

      scenario "should allow user to activate campaigns" do
        campaign = FactoryGirl.create(:inactive_campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: @company)
        Sunspot.commit
        visit campaigns_path

        filter_section('ACTIVE STATE').unicheck('Inactive')

        expect(page).to have_content('Cacique FY13')
        within("ul#campaigns-list li:nth-child(1)") do
          expect(page).to have_content('Cacique FY13')
          click_link('Activate')
        end
        expect(page).to have_no_content('Cacique FY13')
        wait_for_ajax
      end
    end

    scenario 'allows the user to create a new campaign' do
      porfolio = FactoryGirl.create(:brand_portfolio, name: 'Test portfolio', company: @company)
      visit campaigns_path

      click_link('New Campaign')

      within("form#new_campaign") do
        fill_in 'Name', with: 'new campaign name'
        fill_in 'Description', with: 'new campaign description'
        select_from_chosen('Test portfolio', from: 'Brand portfolios', match: :first)
        click_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new campaign name') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'new campaign name')
      expect(page).to have_selector('div.description-data', text: 'new campaign description')
      wait_for_ajax
    end
  end

  feature "/campaigns/:campaign_id", :js => true do
    scenario "GET show should display the campaign details page" do
      campaign = FactoryGirl.create(:campaign, name: 'Some Campaign', description: 'a campaign description', company: @company)
      visit campaign_path(campaign)
      expect(page).to have_selector('h2', text: 'Some Campaign')
      expect(page).to have_selector('div.description-data', text: 'a campaign description')
    end

    scenario 'allows the user to activate/deactivate a campaign' do
      campaign = FactoryGirl.create(:campaign, name: 'Some Campaign', description: 'a campaign description', company: @company)
      visit campaign_path(campaign)
      within('.links-data') do
        click_link('Deactivate')
      end

      confirm_prompt "Are you sure you want to deactivate this campaign?"

      within('.links-data') do
        click_link('Activate')
        expect(page).to have_link('Deactivate') # test the link have changed
      end
      wait_for_ajax
    end

    scenario 'allows the user to edit the campaign' do
      campaign = FactoryGirl.create(:campaign, company: @company)
      visit campaign_path(campaign)

      find('.links-data').click_link('Edit')

      within("form#edit_campaign_#{campaign.id}") do
        fill_in 'Name', with: 'edited campaign name'
        fill_in 'Description', with: 'edited campaign description'
        click_button 'Save'
      end

      #find('h2', text: 'edited campaign name') # Wait for the page to reload
      expect(page).to have_selector('h2', text: 'edited campaign name')
      expect(page).to have_selector('div.description-data', text: 'edited campaign description')
      wait_for_ajax
    end


    scenario "should be able to assign areas to the campaign" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      area = FactoryGirl.create(:area, name: 'San Francisco Area', company: @company)
      visit campaign_path(campaign)

      tab = open_tab('Places')
      within tab do
        click_link 'Add Places'
      end

      within visible_modal do
        find("#area-#{area.id}").click_link('Add Area')
        expect(page).to have_no_selector("#area-#{area.id}")   # The area was removed from the available areas list
      end
      close_modal

      click_link 'Add Places'

      within visible_modal do
        expect(page).to have_no_selector("#area-#{area.id}")   # The area does not longer appear on the list after it was added to the user
      end

      close_modal

      within tab do
        # Ensure the area now appears on the list of areas
        expect(page).to have_content('San Francisco Area')

        # Test the area removal
        click_link 'Remove Area'
        expect(page).to have_no_content('San Francisco Area')
      end
      wait_for_ajax
    end
  end
end