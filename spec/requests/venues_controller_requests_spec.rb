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
    pending "GET index should display a list with the venues" do
      campaign = FactoryGirl.create(:campaign, company: @company)
      venues = []
      with_resque do
        event = FactoryGirl.create(:event, company: @company, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Benito'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 1000}])
        event.venue.update_attribute(:score, 90)
        venues.push event.venue

        event = FactoryGirl.create(:event, company: @company, campaign: campaign,
          place: FactoryGirl.create(:place, name: 'Bar Camelas'),
          results: {impressions: 35, interactions: 65, samples: 15},
          expenses: [{name: 'Expense 1', amount: 2000}])
        event.venue.update_attribute(:score, 95)
        venues.push event.venue
      end

      venues.each {|v| v.reload; p v.inspect }

      Sunspot.commit

      visit venues_path

      within("ul#venues-list") do

        # First Row
        within("li:nth-child(1)") do
          page.should have_content('Costa Rica Team')
          page.should have_selector('span.members>b', text: '3')
          page.should have_content('el grupo de ticos')
        end
        # Second Row
        within("li:nth-child(2)") do
          page.should have_content('San Francisco Team')
           page.should have_selector('span.members>b', text: '2')
          page.should have_content('the guys from SF')
        end
      end

    end
  end


end