require 'spec_helper'

feature "Venues Section", js: true, search: true do
  before do
    @user = FactoryGirl.create(:user, company_id: FactoryGirl.create(:company).id, role_id: FactoryGirl.create(:role).id)
    @company_user = @user.company_users.first
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  feature "List of venues" do
    scenario "a user can play and dismiss the video tutorial" do
      visit venues_path

      feature_name = 'VENUES'

      expect(page).to have_selector('h5', text: feature_name)
      expect(page).to have_content('Welcome to the Venues module!')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit venues_path
      expect(page).to have_no_selector('h5', text: feature_name)
    end

    scenario "GET index should display a list with the venues" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      venues = []
      with_resque do
        event = FactoryGirl.create(:event, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Benito'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 1000}])

        event = FactoryGirl.create(:event, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Camelas'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 2000}])
      end

      Venue.reindex
      Sunspot.commit

      visit venues_path

      within("ul#venues-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Bar Benito')
          expect(page).to have_selector('div.n_spent', text: '$1,000.00')
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Bar Camelas')
          expect(page).to have_selector('div.n_spent', text: '$2,000.00')
        end
      end
    end
  end

  feature "/venues/:venue_id" do
    scenario "a user can play and dismiss the video tutorial" do
      venue = FactoryGirl.create(:venue, company: @company, place: FactoryGirl.create(:place, is_custom_place: true, reference: nil))

      visit venue_path(venue)

      feature_name = 'VENUE DETAILS'

      expect(page).to have_selector('h5', text: feature_name)
      expect(page).to have_content('You are now viewing the Venue Details page')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit venue_path(venue)
      expect(page).to have_no_selector('h5', text: feature_name)
    end
  end
end