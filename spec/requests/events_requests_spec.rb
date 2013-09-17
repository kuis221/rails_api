require 'spec_helper'

describe "Events", js: true, search: true do

  before do
    Warden.test_mode!
    @company = FactoryGirl.create(:company)
    @user = FactoryGirl.create(:user, company: @company, role_id: FactoryGirl.create(:role, company: @company).id)
    @company_user = @user.company_users.first
    sign_in @user
  end

  after do
    Warden.test_reset!
  end

  describe "/events", js: true, search: true  do
    describe "GET index" do
      let(:events){[
        FactoryGirl.create(:event, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '10:00am', end_time: '11:00am', campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012'), active: true, place: FactoryGirl.create(:place, name: 'Place 1'), company: @company),
        FactoryGirl.create(:event, start_date: "08/28/2013", end_date: "08/29/2013", start_time: '11:00am',  end_time: '12:00pm', campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03'), active: true, place: FactoryGirl.create(:place, name: 'Place 2'), company: @company)
      ]}
      it "should display a table with the events" do
        events.size  # make sure users are created before
        Sunspot.commit
        visit events_path

        within("ul#events-list") do
          # First Row
          within("li:nth-child(1)") do
            page.should have_content('WED Aug 21')
            page.should have_content('10:00 AM - 11:00 AM')
            page.should have_content(events[0].place_name)
            page.should have_content('Campaign FY2012')
          end
          # Second Row
          within("li:nth-child(2)")  do
            page.should have_content(events[1].start_at.strftime('WED Aug 28 at 11:00 AM'))
            page.should have_content(events[1].end_at.strftime('THU Aug 29 at 12:00 PM'))
            page.should have_content(events[1].place_name)
            page.should have_content('Another Campaign April 03')
          end
        end

      end

      it "should allow user to activate/deactivate events" do
        events.size  # make sure users are created before
        Sunspot.commit
        visit events_path

        within("ul#events-list") do
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

  end

  describe "/events/:event_id", :js => true do
    it "GET show should display the event details page" do
      event = FactoryGirl.create(:event,
          start_date: '08/28/2013', end_date: '08/28/2013',
          start_time: '8:00 PM', end_time: '11:00 PM',
          campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: @company), company: @company)
      visit event_path(event)
      page.should have_selector('h2', text: 'Campaign FY2012')
      within('.calendar-data') do
        page.should have_content('WED Aug 28')
        page.should have_content('8:00 PM - 11:00 PM')
      end
    end

    it 'allows the user to activate/deactivate a event' do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, company: @company), company: @company)
      visit event_path(event)
      within('.links-data') do
        click_js_link('Deactivate')
        page.should have_selector('a.toggle-active')

        click_js_link('Activate')
        page.should have_selector('a.toggle-inactive')
      end
    end

    it "allows to add a member to the event", :js => true do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: @company), company: @company)
      user = FactoryGirl.create(:user, first_name:'Pablo', last_name:'Baltodano', email: 'palinair@gmail.com', company_id: @company.id, role_id: @company_user.role_id)
      company_user = user.company_users.first
      Sunspot.commit

      visit event_path(event)

      click_js_link 'Add Team Member'
      within "ul#staff-list li#staff-member-user-#{company_user.id}" do
        page.should have_content('Pablo')
        page.should have_content('Baltodano')
        click_js_link("add-member-btn-#{company_user.id}")
      end

      # Test the user was added to the list of event members and it can be removed
      within('#event-team-members #event-member-'+company_user.id.to_s) do
        page.should have_content('Pablo Baltodano')
        #find('a.remove-member-btn').click
      end

      # the user should have been removed from the list
      within "ul#staff-list" do
        page.should_not have_selector("li#staff-member-user-#{company_user.id}")
      end

      # Test removal of the user
      page.execute_script("$('#event-team-members #event-member-#{company_user.id.to_s} a').click()")
      within('.bootbox.modal.confirm-dialog') do
        page.should have_content('Any tasks that are assigned to Pablo Baltodano must be reassigned. Would you like to remove Pablo Baltodano from the event team?')
        #find('a.btn-primary').click   # The "OK" button
        page.execute_script("$('.bootbox.modal.confirm-dialog a.btn-primary').click()")
      end

      # Refresh the page and make sure the user is not there
      visit event_path(event)
      all('#event-team-members .team-member').count.should == 0
    end

    it "allows to create a new task for the event and mark it as completed" do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign), company: @company)
      user = FactoryGirl.create(:user, company: @company, first_name: 'Juanito', last_name: 'Bazooka')
      company_user = user.company_users.first
      event.users << @company_user
      event.users << user.company_users.first
      Sunspot.commit

      visit event_path(event)

      click_js_link 'Create Task'
      within('form#new_task') do
        fill_in 'Title', with: 'Pick up the kidz at school'
        fill_in 'Due at', with: '05/16/2013'
        select_from_chosen('Juanito Bazooka', :from => 'Assigned To')
        click_js_button 'Submit'
        #page.execute_script("$('form#new_task input[type=submit].btn-primary').click()")
      end

      within('#event-tasks-container li') do
        page.should have_content('Pick up the kidz at school')
        page.should have_content('Juanito Bazooka')
        page.should have_content('THU May 16')
      end

      # Mark the tasks as completed
      within('#event-tasks-container') do
        checkbox = find('.task-completed-checkbox', visible: :false)
        checkbox['checked'].should be_false
        page.execute_script('$(\'.task-completed-checkbox\').click()')

        # refresh the page to make sure the checkbox remains selected
        visit event_path(event)
        find('.task-completed-checkbox', visible: :false)['checked'].should be_true
      end

      # Delete Juanito Bazooka from the team and make sure that the tasks list
      # is refreshed and the task unassigned
      page.execute_script("$('#event-member-#{company_user.id.to_s} a.remove-member-btn').click()")
      find('.bootbox.modal.confirm-dialog') # Waits for the dialog to open
      page.execute_script("$('.bootbox.modal.confirm-dialog a.btn-primary').click()")

      # refresh the page to make that the tasks were unassigned
      # TODO: the refresh should not be necessary but it looks like that it's not
      # removing the element from the table automatically in the test
      visit event_path(event)
      within('#event-tasks-container') do
        page.should_not have_content('Juanito Bazooka')
      end
    end
  end

end