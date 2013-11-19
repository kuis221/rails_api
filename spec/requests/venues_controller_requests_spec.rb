require 'spec_helper'

describe "VenuesController", js: true, search: true do
  before do
    @user = login
    sign_in @user
    @company = @user.companies.first
  end

  after do
    Warden.test_reset!
  end

  describe "/venues" do
    it "GET index should display a list with the venues" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      venues = []
      with_resque do
        event = FactoryGirl.create(:event, company: @company, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Benito'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 1000}])
        Sunspot.commit
        event.venue.update_attribute(:spent, 1500)
        Sunspot.index event.venue
        venues.push event.venue
        Sunspot.commit


        event = FactoryGirl.create(:event, company: @company, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Camelas'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 2000}])
        Sunspot.commit
        event.venue.update_attribute(:spent, 2500)
        Sunspot.index event.venue
        venues.push event.venue

        Sunspot.commit
      end

      venues.each {|v| v.reload; Sunspot.index v }

      Sunspot.commit

      visit venues_path

      within("ul#venues-list") do

        # First Row
        within("li:nth-child(1)") do
          page.should have_content('Bar Camelas')
          page.should have_selector('div.n_spent', text: '$2,500.00')
        end
        # Second Row
        within("li:nth-child(2)") do
          page.should have_content('Bar Benito')
           page.should have_selector('div.n_spent', text: '$1,500.00')
        end
      end

    end
  end


end