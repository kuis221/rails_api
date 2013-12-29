require 'spec_helper'

feature "Venues Section", js: true, search: true do
  before do
    @user = login
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  feature "List of venues" do
    scenario "GET index should display a list with the venues" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      venues = []
      with_resque do
        event = FactoryGirl.create(:event, company: @company, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Benito'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 1000}])

        event = FactoryGirl.create(:event, company: @company, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Camelas'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 2000}])
      end

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
      wait_for_ajax
    end
  end


end