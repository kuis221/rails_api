require 'spec_helper'

describe "Events", js: true, search: true do

  before do
    Kpi.destroy_all
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
        FactoryGirl.create(:event, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '10:00am', end_time: '11:00am', campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012',company: @company), active: true, place: FactoryGirl.create(:place, name: 'Place 1'), company: @company),
        FactoryGirl.create(:event, start_date: "08/28/2013", end_date: "08/29/2013", start_time: '11:00am',  end_time: '12:00pm', campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03',company: @company), active: true, place: FactoryGirl.create(:place, name: 'Place 2'), company: @company)
      ]}
      it "should display a table with the events" do
        Timecop.freeze(Time.zone.local(2013, 07, 21, 12, 01)) do
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
      end

      it "should allow user to activate/deactivate events" do
        Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
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

      it "should allow allow filter events by date range" do
        # Make the current date 2013/07/26 so we can play with the calendar
        # more easily
        Timecop.travel(Time.zone.local(2013, 07, 26, 12, 00))
        today = Time.zone.now.to_date
        tomorrow = today+1
        FactoryGirl.create(:event, start_date: today.to_s(:slashes), company: @company, active: true, end_date: today.to_s(:slashes), start_time: '10:00am', end_time: '11:00am',
          campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012',company: @company),
          place: FactoryGirl.create(:place, name: 'Place 1', city: 'Los Angeles', state:'CA', country: 'US')
        )
        FactoryGirl.create(:event, start_date: tomorrow.to_s(:slashes), company: @company, active: true, end_date: tomorrow.to_s(:slashes), start_time: '11:00am',  end_time: '12:00pm',
          campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03',company: @company),
          place: FactoryGirl.create(:place, name: 'Place 2', city: 'Austin', state:'TX', country: 'US'))
        Sunspot.commit

        visit events_path

        within("ul#events-list") do
          page.should have_content('Campaign FY2012')
          page.should have_content('Another Campaign April 03')
        end

        page.should have_filter_section(title: 'CAMPAIGNS', options: ['Campaign FY2012', 'Another Campaign April 03'])
        #page.should have_filter_section(title: 'LOCATIONS', options: ['Los Angeles', 'Austin'])

        filter_section('CAMPAIGNS').unicheck('Campaign FY2012')

        within("ul#events-list") do
          page.should have_no_content('Another Campaign April 03')
          page.should have_content('Campaign FY2012')
        end

        filter_section('CAMPAIGNS').unicheck('Another Campaign April 03')
        within("ul#events-list") do
          page.should have_content('Another Campaign April 03')
          page.should have_content('Campaign FY2012')
        end

        select_filter_calendar_day("26")
        find('#collection-list-filters').should have_no_content('Another Campaign April 03')
        within("ul#events-list") do
          page.should have_no_content('Another Campaign April 03')
          page.should have_content('Campaign FY2012')
        end

        select_filter_calendar_day("26", "27")
        filter_section('CAMPAIGNS').unicheck('Another Campaign April 03')
        within("ul#events-list") do
          page.should have_content('Another Campaign April 03')
          page.should have_content('Campaign FY2012')
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
      within visible_modal do
        page.should have_content('Pablo')
        page.should have_content('Baltodano')
        click_js_link("add-member-btn-#{company_user.id}")

        page.should have_no_selector("li#staff-member-user-#{company_user.id}")
      end
      close_modal

      # Test the user was added to the list of event members and it can be removed
      within event_team_member(company_user) do
        page.should have_content('Pablo Baltodano')
        #find('a.remove-member-btn').click
      end

      # Test removal of the user
      hover_and_click('#event-team-members #event-member-'+company_user.id.to_s, 'Remove Member')


      within visible_modal do
        page.should have_content('Any tasks that are assigned to Pablo Baltodano must be reassigned. Would you like to remove Pablo Baltodano from the event team?')
        #find('a.btn-primary').click   # The "OK" button
        #page.execute_script("$('.bootbox.modal.confirm-dialog a.btn-primary').click()")
        click_js_link('OK')
      end
      ensure_modal_was_closed

      # Refresh the page and make sure the user is not there
      visit event_path(event)
      all('#event-team-members .team-member').count.should == 0
    end


    it "allows to add a user as contact to the event", :js => true do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: @company), company: @company)
      user = FactoryGirl.create(:user, first_name:'Pablo', last_name:'Baltodano', email: 'palinair@gmail.com', company_id: @company.id, role_id: @company_user.role_id)
      company_user = user.company_users.first
      Sunspot.commit

      visit event_path(event)

      click_js_link 'Add Contact'
      within visible_modal do
        page.should have_selector("li#contact-company_user-#{company_user.id}")
        page.should have_content('Pablo')
        page.should have_content('Baltodano')
        click_js_link("add-contact-btn-company_user-#{company_user.id}")

        page.should have_no_selector("li#contact-company_user-#{company_user.id}")
      end
      close_modal

      # Test the user was added to the list of event members and it can be removed
      within "#event-contacts-list" do
        page.should have_content('Pablo Baltodano')
        #find('a.remove-member-btn').click
      end

      # Test removal of the user
      hover_and_click("#event-contacts-list .event-contact", 'Remove Contact')

      # Refresh the page and make sure the user is not there
      visit event_path(event)

      page.should_not have_content('Pablo Baltodano')
    end


    it "allows to add a contact as contact to the event", :js => true do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: @company), company: @company)
      contact = FactoryGirl.create(:contact, first_name:'Guillermo', last_name:'Vargas', email: 'guilleva@gmail.com', company_id: @company.id)
      Sunspot.commit

      visit event_path(event)

      click_js_link 'Add Contact'
      within visible_modal do
        page.should have_selector("li#contact-contact-#{contact.id}")
        page.should have_content('Guillermo')
        page.should have_content('Vargas')
        click_js_link("add-contact-btn-contact-#{contact.id}")

        page.should have_no_selector("li#contact-contact-#{contact.id}")
      end
      close_modal

      # Test the user was added to the list of event members and it can be removed
      within "#event-contacts-list" do
        page.should have_content('Guillermo Vargas')
        #find('a.remove-member-btn').click
      end

      # Test removal of the user
      hover_and_click("#event-contacts-list .event-contact", 'Remove Contact')

      # Refresh the page and make sure the user is not there
      visit event_path(event)

      page.should_not have_content('Guillermo Vargas')
    end


    it "allows to create a contact", :js => true do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: @company), company: @company)
      Sunspot.commit

      visit event_path(event)

      click_js_link 'Add Contact'
      visible_modal.click_js_link("Create New Contact")

      within ".contactevent_modal" do
        fill_in 'First name', with: 'Pedro'
        fill_in 'Last name', with: 'Picapiedra'
        fill_in 'Email', with: 'pedro@racadura.com'
        fill_in 'Phone number', with: '+1 505 22343222'
        fill_in 'Address', with: 'ABC 123'
        select_from_chosen('United States', :from => 'Country')
        select_from_chosen('California', :from => 'State')
        fill_in 'City', with: 'Los Angeles'
        fill_in 'Zip code', with: '12345'
        click_js_button 'Save'
      end

      ensure_modal_was_closed


      # Test the user was added to the list of event members and it can be removed
      within "#event-contacts-list" do
        page.should have_content('Pedro Picapiedra')
      end

      # Test removal of the user
      hover_and_click("#event-contacts-list .event-contact", 'Remove Contact')

      # Refresh the page and make sure the user is not there
      visit event_path(event)

      page.should_not have_content('Pedro Picapiedra')
    end

    it "allows to edit a contact", :js => true do
      event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: @company), company: @company)
      contact = FactoryGirl.create(:contact, first_name:'Guillermo', last_name:'Vargas', email: 'guilleva@gmail.com', company_id: @company.id)
      FactoryGirl.create(:contact_event, event: event, contactable: contact)
      Sunspot.commit

      visit event_path(event)

      page.should have_content('Guillermo Vargas')

      hover_and_click("#event-contacts-list .event-contact", 'Edit Contact')

      within visible_modal do
        fill_in 'First name', with: 'Pedro'
        fill_in 'Last name', with: 'Picapiedra'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      # Test the user was added to the list of event members and it can be removed
      within "#event-contacts-list" do
        page.should have_no_content('Guillermo Vargas')
        page.should have_content('Pedro Picapiedra')
        #find('a.remove-member-btn').click
      end
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

    it "should allow the user to fill the event data" do
      Kpi.create_global_kpis
      event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes),
          end_date: Date.yesterday.to_s(:slashes),
          campaign: FactoryGirl.create(:campaign, company: @company),
          company: @company )
      event.campaign.assign_all_global_kpis

      Sunspot.commit

      visit event_path(event)

      fill_in 'Summary', with: 'This is the summary'

      fill_in '< 12', with: '10'
      fill_in '12 – 17', with: '11'
      fill_in '18 – 24', with: '12'
      fill_in '25 – 34', with: '13'
      fill_in '35 – 44', with: '14'
      fill_in '45 – 54', with: '15'
      fill_in '55 – 64', with: '16'
      fill_in '65+', with: '9'


      fill_in 'Asian', with: '20'
      fill_in 'Black / African American', with: '12'
      fill_in 'Hispanic / Latino', with: '13'
      fill_in 'Native American', with: '34'
      fill_in 'White', with: '21'


      fill_in 'Female', with: '34'
      fill_in 'Male', with: '66'

      fill_in 'Impressions',  with: 100
      fill_in 'Interactions', with: 110
      fill_in 'Samples',      with: 120

      click_button 'Save Result'

      # Ensure the results are displayed on the page

      within "#ethnicity-graph" do
        page.should have_content "20%"
        page.should have_content "12%"
        page.should have_content "13%"
        page.should have_content "34%"
        page.should have_content "21%"
      end

      within "#gender-graph" do
        page.should have_content "34 %"
        page.should have_content "66 %"
      end

      within "#age-graph" do
        page.should have_content "9%"
        page.should have_content "11%"
        page.should have_content "12%"
        page.should have_content "13%"
        page.should have_content "14%"
        page.should have_content "15%"
        page.should have_content "16%"
      end

      visit event_path(event)

      # Page should still display the post-event format and not the form
      page.should have_selector("#gender-graph")
      page.should have_selector("#ethnicity-graph")
      page.should have_selector("#age-graph")

      click_link 'Edit event data'

      fill_in 'Summary', with: 'Edited summary content'
      fill_in 'Impressions', with: '3333'
      fill_in 'Interactions', with: '222222'
      fill_in 'Samples', with: '4444444'

      click_button "Save"

      within ".box_metrics" do
        save_and_open_page
        page.should have_content('3,333')
        page.should have_content('222,222')
        page.should have_content('4,444,444')
      end

      page.should have_content('Edited summary content')
    end
  end

end