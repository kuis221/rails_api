require 'spec_helper'

describe "Campaigns", js: true, search: true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company = @user.companies.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  describe "/campaigns" do
    describe "GET index" do
      it "should display a table with the campaigns" do
        campaigns = [
          FactoryGirl.create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: @company),
          FactoryGirl.create(:campaign, name: 'Centenario FY12', description: 'ron Centenario test campaign', company: @company)
        ]
        Sunspot.commit
        visit campaigns_path

        within("ul#campaigns-list") do
          # First Row
          within("li:nth-child(1)") do
            page.should have_content(campaigns[0].name)
            page.should have_content(campaigns[0].description)
          end
          # Second Row
          within("li:nth-child(2)") do
            page.should have_content(campaigns[1].name)
            page.should have_content(campaigns[1].description)
          end
        end

      end

      it "should allow user to activate/deactivate Campaigns" do
        FactoryGirl.create(:campaign, name: 'Cacique FY13', description: 'test campaign for guaro cacique', company: @company)
        Sunspot.commit
        visit campaigns_path

        within("ul#campaigns-list") do
          # First Row
          within("li:nth-child(1)") do
            click_js_link('Deactivate')
            page.should have_selector('a.enable', text: '')

            click_js_link('Activate')
            page.should have_selector('a.disable', text: '')
          end
        end
      end

    end

    it 'allows the user to create a new campaign' do
      porfolio = FactoryGirl.create(:brand_portfolio, name: 'Test porfolio')
      visit campaigns_path

      click_js_link('New Campaign')

      within("form#new_campaign") do
        fill_in 'Name', with: 'new campaign name'
        fill_in 'Description', with: 'new campaign description'
        select_from_chosen('Test porfolio', from: 'Brand portfolios', match: :first)
        click_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'new campaign name') # Wait for the page to load
      page.should have_selector('h2', text: 'new campaign name')
      page.should have_selector('div.description-data', text: 'new campaign description')
    end
  end

  describe "/campaigns/:campaign_id", :js => true do
    it "GET show should display the campaign details page" do
      campaign = FactoryGirl.create(:campaign, name: 'Some Campaign', description: 'a campaign description', company: @company)
      visit campaign_path(campaign)
      page.should have_selector('h2', text: 'Some Campaign')
      page.should have_selector('div.description-data', text: 'a campaign description')
    end

    it 'allows the user to activate/deactivate a campaign' do
      campaign = FactoryGirl.create(:campaign, name: 'Some Campaign', description: 'a campaign description', company: @company)
      visit campaign_path(campaign)
      within('.links-data') do
        click_js_link('Deactivate')
        page.should have_selector('a.toggle-active')

        click_js_link('Activate')
        page.should have_selector('a.toggle-inactive')
      end
    end

    it 'allows the user to edit the campaign' do
      campaign = FactoryGirl.create(:campaign, company: @company)
      visit campaign_path(campaign)

      find('.links-data').click_js_link('Edit')

      within("form#edit_campaign_#{campaign.id}") do
        fill_in 'Name', with: 'edited campaign name'
        fill_in 'Description', with: 'edited campaign description'
        click_button 'Save'
      end

      find('h2', text: 'edited campaign name') # Wait for the page to reload
      page.should have_selector('h2', text: 'edited campaign name')
      page.should have_selector('div.description-data', text: 'edited campaign description')
    end


    it "should be able to assign areas to the campaign" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      area = FactoryGirl.create(:area, name: 'San Francisco Area', company: @company)
      visit campaign_path(campaign)

      tab = open_tab('Places')
      within tab do

        click_js_link 'Add Places'
      end

      within visible_modal do
        find("#area-#{area.id}").click_js_link('Add Area')
        page.should have_no_selector("#area-#{area.id}")   # The area was removed from the available areas list
      end
      close_modal

      click_js_link 'Add Places'

      within visible_modal do
        page.should have_no_selector("#area-#{area.id}")   # The area does not longer appear on the list after it was added to the user
      end

      close_modal

      within tab do
        # Ensure the area now appears on the list of areas
        page.should have_content('San Francisco Area')

        # Test the area removal
        click_js_link 'Remove Area'
        page.should have_no_content('San Francisco Area')
      end
    end

  end

end