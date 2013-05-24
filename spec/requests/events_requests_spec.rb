require 'spec_helper'

def test_sorting(table)
  within table do
    count = all('tbody tr').count
    ids = all('tbody tr').map {|row| row['id']}
    all('thead th[data-sort]').each do |th|
      page.execute_script("$('#{table} tbody').empty()")
      all('tbody tr').count.should == 0
      th.click
      find('tbody tr:first-child') # Wait until the rows have been loaded
      all('tbody tr').count.should == count
      new_ids = all('tbody tr').map {|row| row['id']}
      new_ids.should =~ ids
    end
  end
end

describe "Events", :js => true do

  before do
    Warden.test_mode!
    @user = FactoryGirl.create(:user, company: FactoryGirl.create(:company))
    sign_in @user
    Place.any_instance.stub(:fetch_place_data).and_return(true)
  end

  after do
    Warden.test_reset!
  end

  describe "/events" do
    it "GET index should display a table with the events" do
      events = [
        FactoryGirl.create(:event, start_at: Date.today, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012'), active: true, place: FactoryGirl.create(:place, name: 'Place 1')),
        FactoryGirl.create(:event, start_at: Date.today+1.hour, campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03'), active: false, place: FactoryGirl.create(:place, name: 'Place 2'))
      ]
      visit events_path

      within("table#events-list") do
        # First Row
        within("tbody tr:nth-child(1)") do
          find('td:nth-child(1)').should have_content(events[0].start_date.to_s)
          find('td:nth-child(2)').should have_content(events[0].start_at.to_s(:time_only))
          find('td:nth-child(3)').should have_content(events[0].place_name)
          find('td:nth-child(4)').should have_content(events[0].campaign_name)
          find('td:nth-child(5)').should have_content('Active')
          find('td:nth-child(6)').should have_content('Edit')
          find('td:nth-child(6)').should have_content('Deactivate')
        end
        # Second Row
        within("tbody tr:nth-child(2)") do
          find('td:nth-child(1)').should have_content(events[1].start_date.to_s)
          find('td:nth-child(2)').should have_content(events[1].start_at.to_s(:time_only))
          find('td:nth-child(3)').should have_content(events[1].place_name)
          find('td:nth-child(4)').should have_content(events[1].campaign_name)
          find('td:nth-child(5)').should have_content('Inactive')
          find('td:nth-child(6)').should have_content('Edit')
          find('td:nth-child(6)').should have_content('Activate')
        end
      end

      test_sorting ("table#events-list")

    end
  end

  describe "/events/:event_id", :js => true do
    it "GET show should display the event details page" do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012'))
      visit event_path(event)
      page.should have_selector('h2', text: 'Campaign FY2012')
    end

    it "allows to add a member to the event", :js => true do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012'))
      visit event_path(event)
      user = FactoryGirl.create(:user, first_name:'Pablo', last_name:'Baltodano', email: 'palinair@gmail.com')
      click_link 'Add'
      find("table#select-users-list tr#user-#{user.id}") # Make sure the lighbox is opened
      within("table#select-users-list tr#user-#{user.id}") do
        page.should have_content('Pablo')
        page.should have_content('Baltodano')
        #click_link 'Add' For some reason using click_link is not working here
        page.find('a').trigger('click')
      end

      # Test the user was added to the list of event members and it can be removed
      within('#event-team-members #team-member-'+user.id.to_s) do
        page.should have_content('Pablo Baltodano')
        page.should have_content('palinair@gmail.com')
        #find('a.remove-member-btn').click
        p "$('#event-team-members #team-member-#{user.id.to_s} a').click()"
        page.execute_script("$('#event-team-members #team-member-#{user.id.to_s} a').click()")
      end

      # Refresh the page and make sure the user is not there
      visit event_path(event)
      all('#event-team-members .team-member').count.should == 0
    end

  end

end