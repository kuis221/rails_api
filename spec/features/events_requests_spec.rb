require 'spec_helper'

feature 'Events section' do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }
  let(:event) { FactoryGirl.create(:event, campaign: campaign, company: company) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for 'a user that can activate/deactivate events' do
    let(:events){[
        FactoryGirl.create(:event, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '10:00am', end_time: '11:00am', campaign: campaign, active: true, place: place),
        FactoryGirl.create(:event, start_date: "08/28/2013", end_date: "08/29/2013", start_time: '11:00am', end_time: '12:00pm', campaign: campaign, active: true, place: place)
      ]}
    scenario "should allow user to deactivate events from the event list" do
      Timecop.travel(Time.zone.local(2013, 07, 30, 12, 01)) do
        events.size  # make sure events are created before
        Sunspot.index events
        Sunspot.commit
        visit events_path

        within event_list_item events.first do
          click_js_link 'Deactivate'
        end

        confirm_prompt 'Are you sure you want to deactivate this event?'

        expect(page).to have_no_selector event_list_item(events.first)
      end
    end

    scenario "should allow user to activate events" do
      Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
        events.each{|e| e.deactivate! } # Deactivate the events
        Sunspot.commit
        visit events_path

        # Show only inactive items
        filter_section('ACTIVE STATE').unicheck('Inactive')
        filter_section('ACTIVE STATE').unicheck('Active')

        within event_list_item events.first do
          click_js_link('Activate')
        end
        expect(page).to have_no_selector event_list_item(events.first)
      end
    end

    scenario 'allows the user to activate/deactivate a event from the event details page' do
      visit event_path(events.first)
      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this event?'

      within('.links-data') do
        click_js_link('Activate')
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end
  end

  feature "non admin user", js: true, search: true do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_should_behave_like "a user that can activate/deactivate events" do
      before { company_user.campaigns << campaign }
      before { company_user.places << FactoryGirl.create(:place, city: nil, state: 'San Jose', country: 'CR', types: ['locality']) }
      let(:permissions) { [[:index, 'Event'], [:view_list, 'Event'], [:deactivate, 'Event'], [:show, 'Event']] }
    end
  end

  feature "admin user", js: true, search: true do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user that can activate/deactivate events"

    feature "/events", js: true, search: true  do
      after do
        Timecop.return
      end
      feature "GET index" do
        let(:events){[
            FactoryGirl.create(:event, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '10:00am', end_time: '11:00am', campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012',company: company), active: true, place: FactoryGirl.create(:place, name: 'Place 1'), company: company),
            FactoryGirl.create(:event, start_date: "08/28/2013", end_date: "08/29/2013", start_time: '11:00am', end_time: '12:00pm', campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03',company: company), active: true, place: FactoryGirl.create(:place, name: 'Place 2'), company: company)
          ]}
        scenario "should display a list of events" do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            events.size  # make sure users are created before
            Sunspot.commit
            visit events_path

            within("ul#events-list") do
              # First Row
              within("li:nth-child(1)") do
                expect(page).to have_content('WED Aug 21')
                expect(page).to have_content('10:00 AM - 11:00 AM')
                expect(page).to have_content(events[0].place_name)
                expect(page).to have_content('Campaign FY2012')
              end
              # Second Row
              within("li:nth-child(2)")  do
                expect(page).to have_content(events[1].start_at.strftime('WED Aug 28 at 11:00 AM'))
                expect(page).to have_content(events[1].end_at.strftime('THU Aug 29 at 12:00 PM'))
                expect(page).to have_content(events[1].place_name)
                expect(page).to have_content('Another Campaign April 03')
              end
            end
          end
        end

        scenario "should allow allow filter events by date range" do
          today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
          tomorrow = today+1.day
          Timecop.travel(today) do
            FactoryGirl.create(:event, start_date: today.to_s(:slashes), company: company, active: true, end_date: today.to_s(:slashes), start_time: '10:00am', end_time: '11:00am',
              campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012',company: company),
              place: FactoryGirl.create(:place, name: 'Place 1', city: 'Los Angeles', state:'CA', country: 'US'))
            FactoryGirl.create(:event, start_date: tomorrow.to_s(:slashes), company: company, active: true, end_date: tomorrow.to_s(:slashes), start_time: '11:00am',  end_time: '12:00pm',
              campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03',company: company),
              place: FactoryGirl.create(:place, name: 'Place 2', city: 'Austin', state:'TX', country: 'US'))
            Sunspot.commit

            visit events_path

            expect(page).to have_content('2 Active events taking place today and in the future')

            within("ul#events-list") do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
            end

            expect(page).to have_filter_section(title: 'CAMPAIGNS', options: ['Campaign FY2012', 'Another Campaign April 03'])
            #expect(page).to have_filter_section(title: 'LOCATIONS', options: ['Los Angeles', 'Austin'])

            filter_section('CAMPAIGNS').unicheck('Campaign FY2012')

            expect(page).to have_content('1 Active event as part of Campaign FY2012')

            within("ul#events-list") do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            filter_section('CAMPAIGNS').unicheck('Another Campaign April 03')
            within("ul#events-list") do
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            expect(page).to have_content('2 Active events as part of Another Campaign April 03 and Campaign FY2012')

            select_filter_calendar_day("18")
            find('#collection-list-filters').should have_content('Another Campaign April 03')
            within("ul#events-list") do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            expect(page).to have_content("1 Active event taking place today as part of Another Campaign April 03 and Campaign FY2012")

            select_filter_calendar_day("18", "19")
            within("ul#events-list") do
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            expect(page).to have_content("2 Active events taking place between today and tomorrow as part of Another Campaign April 03 and Campaign FY2012")
          end
        end

        scenario "Filters are preserved upon navigation" do
          today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
          tomorrow = today+1.day
          Timecop.travel(today) do
            ev1 = FactoryGirl.create(:event, start_date: today.to_s(:slashes), company: company, active: true, end_date: today.to_s(:slashes), start_time: '10:00am', end_time: '11:00am',
              campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012',company: company),
              place: FactoryGirl.create(:place, name: 'Place 1', city: 'Los Angeles', state:'CA', country: 'US'))
            ev2 = FactoryGirl.create(:event, start_date: tomorrow.to_s(:slashes), company: company, active: true, end_date: tomorrow.to_s(:slashes), start_time: '11:00am',  end_time: '12:00pm',
              campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03',company: company),
              place: FactoryGirl.create(:place, name: 'Place 2', city: 'Austin', state:'TX', country: 'US'))
            Sunspot.commit

            visit events_path

            filter_section('CAMPAIGNS').unicheck('Campaign FY2012')
            select_filter_calendar_day("18")

            within("ul#events-list") do
              click_js_link('Event Details')
            end

            expect(page).to have_selector('h2', text: ev1.campaign_name)
            current_path.should == event_path(ev1)

            close_resource_details

            expect(page).to have_content("1 Active event taking place today as part of Campaign FY2012")
            current_path.should == events_path

            within("ul#events-list") do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end
          end
        end

        scenario "first filter should make the list show events in the past" do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            campaign    = FactoryGirl.create(:campaign, name: 'ABSOLUT BA FY14', company: company)
            past_event  = FactoryGirl.create(:event, campaign: campaign, company: company,
              start_date: '07/07/2013', end_date: '07/07/2013')
            today_event = FactoryGirl.create(:event, campaign: campaign, company: company,
              start_date: '07/21/2013', end_date:'07/21/2013')
            Sunspot.commit

            visit events_path
            expect(page).to have_content('1 Active event taking place today and in the future')
            expect(page).to have_selector('ul#events-list li', count: 1)

            filter_section('CAMPAIGNS').unicheck('ABSOLUT BA FY14')
            expect(page).to have_content('2 Active events as part of ABSOLUT BA FY14')  # The list shouldn't be filtered by date
            expect(page).to have_selector('ul#events-list li', count: 2)
          end
        end

        scenario "clear filters should also exclude reset the default dates filter" do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            campaign    = FactoryGirl.create(:campaign, name: 'ABSOLUT BA FY14', company: company)
            past_event  = FactoryGirl.create(:event, campaign: campaign, company: company,
              start_date: '07/11/2013', end_date:'07/11/2013')
            today_event = FactoryGirl.create(:event, campaign: campaign, company: company,
              start_date: '07/21/2013', end_date: '07/21/2013')
            Sunspot.commit

            visit events_path
            expect(page).to have_content('1 Active event taking place today and in the future')
            expect(page).to have_selector('ul#events-list li', count: 1)

            click_link 'Clear filters'
            expect(page).to have_content('2 Active events')  # The list shouldn't be filtered by date
            expect(page).to have_selector('ul#events-list li', count: 2)

            filter_section('CAMPAIGNS').unicheck('ABSOLUT BA FY14')
            expect(page).to have_content('2 Active events as part of ABSOLUT BA FY14')  # The list shouldn't be filtered by date
            expect(page).to have_selector('ul#events-list li', count: 2)
          end
        end

        feature "with timezone support turned ON" do
          before do
            company.update_column(:timezone_support, true)
            user.reload
          end
          scenario "should display the dates relative to event's timezone" do
            Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
              # Create a event with the time zone "Central America"
              Time.use_zone('Central America') do
                FactoryGirl.create(:event, start_date: "08/21/2013", end_date: "08/21/2013", start_time: '10:00am', end_time: '11:00am', company: company)
              end

              # Just to make sure the current user is not in the same timezone
              user.time_zone.should == 'Pacific Time (US & Canada)'

              Sunspot.commit
              visit events_path

              within("ul#events-list li:nth-child(1)") do
                expect(page).to have_content('WED Aug 21')
                expect(page).to have_content('10:00 AM - 11:00 AM')
              end
            end
          end
        end
        feature "filters" do
          scenario "Users must be able to filter on all brands they have permissions to access " do
            today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
            tomorrow = today+1.day
            Timecop.travel(today) do
              ev1 = FactoryGirl.create(:event, start_date: today.to_s(:slashes), company: company, active: true, end_date: today.to_s(:slashes), start_time: '10:00am', end_time: '11:00am',
                campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012',company: company),
                place: FactoryGirl.create(:place, name: 'Place 1', city: 'Los Angeles', state:'CA', country: 'US'))
              ev2 = FactoryGirl.create(:event, start_date: tomorrow.to_s(:slashes), company: company, active: true, end_date: tomorrow.to_s(:slashes), start_time: '11:00am',  end_time: '12:00pm',
                campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03',company: company),
                place: FactoryGirl.create(:place, name: 'Place 2', city: 'Austin', state:'TX', country: 'US'))
              brands = [
                FactoryGirl.create(:brand, name: 'Cacique'),
                FactoryGirl.create(:brand, name: 'Smirnoff'),
              ]
              FactoryGirl.create(:brand, name: 'Centenario')  # Brand not added to the user/campaing
              ev1.campaign.brands << brands.first
              ev2.campaign.brands << brands.last
              company_user.brands << brands
              Sunspot.commit
              visit events_path
              expect(page).to have_filter_section(title: 'BRANDS', options: ['Cacique', 'Smirnoff'])

              within("ul#events-list") do
                expect(page).to have_content('Campaign FY2012')
                expect(page).to have_content('Another Campaign April 03')
              end

              filter_section('BRANDS').unicheck('Cacique')

              within("ul#events-list") do
                expect(page).to have_content('Campaign FY2012')
                expect(page).to have_no_content('Another Campaign April 03')
              end
              filter_section('BRANDS').unicheck('Cacique')   # Deselect Cacique
              filter_section('BRANDS').unicheck('Smirnoff')

              within("ul#events-list") do
                expect(page).to have_no_content('Campaign FY2012')
                expect(page).to have_content('Another Campaign April 03')
              end
            end
          end

          scenario "Users must be able to filter on all areas they have permissions to access " do
            ev1 = FactoryGirl.create(:event, company: company, active: true,
              campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012',company: company),
              place: FactoryGirl.create(:place, name: 'Place 1', city: 'Los Angeles', state:'CA', country: 'US'))
            ev2 = FactoryGirl.create(:event, company: company, active: true,
              campaign: FactoryGirl.create(:campaign, name: 'Another Campaign April 03',company: company),
              place: FactoryGirl.create(:place, name: 'Place 2', city: 'Austin', state:'TX', country: 'US'))
            areas = [
              FactoryGirl.create(:area, name: 'Gran Area Metropolitana', description: 'Ciudades principales de Costa Rica', active: true, company: company),
              FactoryGirl.create(:area, name: 'Zona Norte', description: 'Ciudades del Norte de Costa Rica', active: true, company: company)
            ]
            areas.each do |area|
              company_user.areas << area
            end
            Sunspot.commit

            visit events_path
            expect(page).to have_filter_section(title: 'AREAS', options: ['Gran Area Metropolitana', 'Zona Norte'])
          end
        end
      end
    end

    feature "create a event" do
      scenario "allows to create a new event" do
        FactoryGirl.create(:campaign, company: company, name: 'ABSOLUT Vodka')
        visit events_path

        click_button 'Create'

        within visible_modal do
          select_from_chosen('ABSOLUT Vodka', from: 'Campaign')
          click_button 'Create'
        end
        ensure_modal_was_closed
        expect(page).to have_content('ABSOLUT Vodka')
      end
    end


    feature "edit a event" do
      scenario "allows to edit a event" do
        FactoryGirl.create(:campaign, company: company, name: 'ABSOLUT Vodka FY2013')
        event = FactoryGirl.create(:event,
          start_date: 3.days.from_now.to_s(:slashes), end_date: 3.days.from_now.to_s(:slashes),
          start_time: '8:00 PM', end_time: '11:00 PM',
          campaign: FactoryGirl.create(:campaign, name: 'ABSOLUT Vodka FY2012', company: company), company: company)
        Sunspot.commit

        visit events_path

        within("ul#events-list") do
          click_js_link 'Edit'
        end

        within visible_modal do
          find_field('Start date').value.should == 3.days.from_now.to_s(:slashes)
          find_field('End date').value.should == 3.days.from_now.to_s(:slashes)
          find_field('Start time').value.should == '8:00pm'
          find_field('End time').value.should == '11:00pm'

          select_from_chosen('ABSOLUT Vodka FY2013', from: 'Campaign')
          click_js_button 'Save'
        end
        ensure_modal_was_closed
        expect(page).to have_content('ABSOLUT Vodka FY2013')
      end

      feature "with timezone support turned ON" do
        before do
          company.update_column(:timezone_support, true)
          user.reload
        end
        scenario "should display the dates relative to event's timezone" do
          date = 3.days.from_now.to_s(:slashes)
          Time.use_zone('America/Guatemala') do
            event = FactoryGirl.create(:event,
              start_date: date, end_date: date,
              start_time: '8:00 PM', end_time: '11:00 PM',
              campaign: FactoryGirl.create(:campaign, name: 'ABSOLUT Vodka FY2012', company: company), company: company)
          end

          Sunspot.commit

          Time.use_zone('America/New_York') do
            visit events_path

            within("ul#events-list") do
              click_js_link 'Edit'
            end

            within visible_modal do
              find_field('Start date').value.should == date
              find_field('End date').value.should == date
              find_field('Start time').value.should == '8:00pm'
              find_field('End time').value.should == '11:00pm'

              fill_in('Start time', with: '10:00pm')
              fill_in('End time', with: '11:00pm')

              click_button 'Save'
            end
            ensure_modal_was_closed
            expect(page).to have_content('10:00 PM - 11:00 PM')
          end

          # Check that the event's time is displayed with the same time in a different tiem zone
          Time.use_zone('America/Los_Angeles') do
            visit events_path
            within("ul#events-list") do
              expect(page).to have_content('10:00 PM - 11:00 PM')
            end
          end
        end
      end
    end

    feature "/events/:event_id", :js => true do
      scenario "GET show should display the event details page" do
        event = FactoryGirl.create(:event,
          start_date: '08/28/2013', end_date: '08/28/2013',
          start_time: '8:00 PM', end_time: '11:00 PM',
          campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: company), company: company)
        visit event_path(event)
        expect(page).to have_selector('h2', text: 'Campaign FY2012')
        within('.calendar-data') do
          expect(page).to have_content('WED Aug 28')
          expect(page).to have_content('8:00 PM - 11:00 PM')
        end
      end

      feature "with timezone suport turned ON" do
        before do
          company.update_column(:timezone_support, true)
          user.reload
        end

        scenario "should display the dates relative to event's timezone" do
          event = nil
          # Create a event with the time zone "Central America"
          Time.use_zone('Central America') do
            event = FactoryGirl.create(:event,
              start_date: "08/21/2013", end_date: "08/21/2013", start_time: '10:00am', end_time: '11:00am',
              campaign: FactoryGirl.create(:campaign, company: company), company: company)
          end

          # Just to make sure the current user is not in the same timezone
          user.time_zone.should == 'Pacific Time (US & Canada)'

          Sunspot.commit
          visit event_path(event)

          within('.calendar-data') do
            expect(page).to have_content('WED Aug 21')
            expect(page).to have_content('10:00 AM - 11:00 AM')
          end
        end
      end

      scenario "allows to add a member to the event", :js => true do
        event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: company), company: company)
        pablo = FactoryGirl.create(:user, first_name:'Pablo', last_name:'Baltodano', email: 'palinair@gmail.com', company_id: company.id, role_id: company_user.role_id)
        pablo_user = pablo.company_users.first
        Sunspot.commit

        visit event_path(event)

        click_js_link 'Add Team Member'
        within visible_modal do
          expect(page).to have_content('Pablo')
          expect(page).to have_content('Baltodano')
          click_js_link("add-member-btn-#{pablo_user.id}")

          expect(page).to have_no_selector("li#staff-member-user-#{pablo_user.id}")
        end
        close_modal

        # Test the user was added to the list of event members and it can be removed
        within event_team_member(pablo_user) do
          expect(page).to have_content('Pablo Baltodano')
          #find('a.remove-member-btn').click
        end

        # Test removal of the user
        hover_and_click('#event-team-members #event-member-'+pablo_user.id.to_s, 'Remove Member')

        confirm_prompt 'Any tasks that are assigned to Pablo Baltodano must be reassigned. Would you like to remove Pablo Baltodano from the event team?'

        # Refresh the page and make sure the user is not there
        visit event_path(event)
        all('#event-team-members .team-member').count.should == 1
      end


      scenario "allows to add a user as contact to the event", :js => true do
        event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: company), company: company)
        pablo = FactoryGirl.create(:user, first_name:'Pablo', last_name:'Baltodano', email: 'palinair@gmail.com', company_id: company.id, role_id: company_user.role_id)
        pablo_user = pablo.company_users.first
        Sunspot.commit

        visit event_path(event)

        click_js_link 'Add Contact'
        within visible_modal do
          fill_in 'contact-search-box', with: 'Pab'
          expect(page).to have_selector("li#contact-company_user-#{pablo_user.id}")
          expect(page).to have_content('Pablo')
          expect(page).to have_content('Baltodano')
          click_js_link("add-contact-btn-company_user-#{pablo_user.id}")

          expect(page).to have_no_selector("li#contact-company_user-#{pablo_user.id}")
        end
        close_modal

        # Test the user was added to the list of event members and it can be removed
        within "#event-contacts-list" do
          expect(page).to have_content('Pablo Baltodano')
          #find('a.remove-member-btn').click
        end

        # Test removal of the user
        hover_and_click("#event-contacts-list .event-contact", 'Remove Contact')

        # Refresh the page and make sure the user is not there
        visit event_path(event)

        expect(page).to_not have_content('Pablo Baltodano')
      end


      scenario "allows to add a contact as contact to the event", :js => true do
        event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: company), company: company)
        contact = FactoryGirl.create(:contact, first_name:'Guillermo', last_name:'Vargas', email: 'guilleva@gmail.com', company_id: company.id)
        Sunspot.commit

        visit event_path(event)

        click_js_link 'Add Contact'
        within visible_modal do
          fill_in 'contact-search-box', with: 'Gui'
          expect(page).to have_selector("li#contact-contact-#{contact.id}")
          expect(page).to have_content('Guillermo')
          expect(page).to have_content('Vargas')
          click_js_link("add-contact-btn-contact-#{contact.id}")

          expect(page).to have_no_selector("li#contact-contact-#{contact.id}")
        end
        close_modal

        # Test the user was added to the list of event members and it can be removed
        within "#event-contacts-list" do
          expect(page).to have_content('Guillermo Vargas')
          #find('a.remove-member-btn').click
        end

        # Test removal of the user
        hover_and_click("#event-contacts-list .event-contact", 'Remove Contact')

        # Refresh the page and make sure the user is not there
        visit event_path(event)

        expect(page).to_not have_content('Guillermo Vargas')
      end


      scenario "allows to create a contact", :js => true do
        event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: company), company: company)
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
          expect(page).to have_content('Pedro Picapiedra')
        end

        # Test removal of the user
        hover_and_click("#event-contacts-list .event-contact", 'Remove Contact')

        # Refresh the page and make sure the user is not there
        visit event_path(event)

        expect(page).to_not have_content('Pedro Picapiedra')
      end

      scenario "allows to edit a contact", :js => true do
        event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, name: 'Campaign FY2012', company: company), company: company)
        contact = FactoryGirl.create(:contact, first_name:'Guillermo', last_name:'Vargas', email: 'guilleva@gmail.com', company_id: company.id)
        FactoryGirl.create(:contact_event, event: event, contactable: contact)
        Sunspot.commit

        visit event_path(event)

        expect(page).to have_content('Guillermo Vargas')

        hover_and_click("#event-contacts-list .event-contact", 'Edit Contact')

        within visible_modal do
          fill_in 'First name', with: 'Pedro'
          fill_in 'Last name', with: 'Picapiedra'
          click_js_button 'Save'
        end
        sleep 1
        ensure_modal_was_closed

        # Test the user was added to the list of event members and it can be removed
        within "#event-contacts-list" do
          expect(page).to have_no_content('Guillermo Vargas')
          expect(page).to have_content('Pedro Picapiedra')
          #find('a.remove-member-btn').click
        end
      end

      scenario "allows to create a new task for the event and mark it as completed" do
        event = FactoryGirl.create(:event, campaign: FactoryGirl.create(:campaign, company: company))
        juanito = FactoryGirl.create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
        juanito_user = juanito.company_users.first
        event.users << juanito_user
        event.users << user.company_users.first
        Sunspot.commit

        visit event_path(event)

        click_js_link 'Create Task'
        within('form#new_task') do
          fill_in 'Title', with: 'Pick up the kidz at school'
          fill_in 'Due at', with: '05/16/2013'
          select_from_chosen('Juanito Bazooka', :from => 'Assigned To')
          click_js_button 'Submit'
        end

        expect(page).to have_text('0 UNASSIGNED')
        expect(page).to have_text('0 COMPLETED')
        expect(page).to have_text('1 ASSIGNED')
        expect(page).to have_text('1 LATE')

        within('#event-tasks-container li') do
          expect(page).to have_content('Pick up the kidz at school')
          expect(page).to have_content('Juanito Bazooka')
          expect(page).to have_content('THU May 16')
        end

        # Mark the tasks as completed
        within('#event-tasks-container') do
          checkbox = find('.task-completed-checkbox', visible: :false)
          checkbox['checked'].should be_false
          find('.task-completed-checkbox').trigger('click')
          wait_for_ajax

          # refresh the page to make sure the checkbox remains selected
          visit event_path(event)
          find('.task-completed-checkbox', visible: :false)['checked'].should be_true
        end

        # Check that the totals where properly updated
        expect(page).to have_text('0 UNASSIGNED')
        expect(page).to have_text('1 COMPLETED')
        expect(page).to have_text('1 ASSIGNED')
        expect(page).to have_text('0 LATE')

        # Delete Juanito Bazooka from the team and make sure that the tasks list
        # is refreshed and the task unassigned
        hover_and_click("#event-member-#{juanito_user.id.to_s}", 'Remove Member')
        confirm_prompt 'Any tasks that are assigned to Juanito Bazooka must be reassigned. Would you like to remove Juanito Bazooka from the event team?'

        # refresh the page to make that the tasks were unassigned
        # TODO: the refresh should not be necessary but it looks like that it's not
        # removing the element from the table automatically in the test
        visit event_path(event)
        within('#event-tasks-container') do
          expect(page).to_not have_content('Juanito Bazooka')
        end
      end

      scenario "should allow the user to fill the event data" do
        Kpi.create_global_kpis
        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes),
          end_date: Date.yesterday.to_s(:slashes),
          campaign: FactoryGirl.create(:campaign, company: company),
          company: company )
        event.campaign.assign_all_global_kpis

        event.campaign.add_kpi FactoryGirl.create(:kpi, name: 'Integer field', kpi_type: 'number', capture_mechanism: 'integer')
        event.campaign.add_kpi FactoryGirl.create(:kpi, name: 'Decimal field', kpi_type: 'number', capture_mechanism: 'decimal')
        event.campaign.add_kpi FactoryGirl.create(:kpi, name: 'Currency field', kpi_type: 'number', capture_mechanism: 'currency')
        event.campaign.add_kpi FactoryGirl.create(:kpi, name: 'Radio field', kpi_type: 'count', capture_mechanism: 'radio', kpis_segments: [
            FactoryGirl.create(:kpis_segment, text: 'Radio Option 1'),
            FactoryGirl.create(:kpis_segment, text: 'Radio Option 2')
          ])

        event.campaign.add_kpi FactoryGirl.create(:kpi, name: 'Checkbox field', kpi_type: 'count', capture_mechanism: 'checkbox', kpis_segments: [
            FactoryGirl.create(:kpis_segment, text: 'Checkbox Option 1'),
            FactoryGirl.create(:kpis_segment, text: 'Checkbox Option 2'),
            FactoryGirl.create(:kpis_segment, text: 'Checkbox Option 3')
          ])

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

        fill_in 'Integer field', with: '99'
        fill_in 'Decimal field', with: '99.9'
        fill_in 'Currency field', with: '79.9'

        choose('Radio Option 1')

        unicheck('Checkbox Option 1')
        unicheck('Checkbox Option 2')

        click_button 'Save'

        # Ensure the results are displayed on the page

        within "#ethnicity-graph" do
          expect(page).to have_content "20%"
          expect(page).to have_content "12%"
          expect(page).to have_content "13%"
          expect(page).to have_content "34%"
          expect(page).to have_content "21%"
        end

        within "#gender-graph" do
          expect(page).to have_content "34 %"
          expect(page).to have_content "66 %"
        end

        within "#age-graph" do
          expect(page).to have_content "9%"
          expect(page).to have_content "11%"
          expect(page).to have_content "12%"
          expect(page).to have_content "13%"
          expect(page).to have_content "14%"
          expect(page).to have_content "15%"
          expect(page).to have_content "16%"
        end

        within ".box_metrics" do
          expect(page).to have_content('99 INTEGER FIELD')
          expect(page).to have_content('99.9 DECIMAL FIELD')
          expect(page).to have_content('$79.90 CURRENCY FIELD')
          expect(page).to have_content('$79.90 CURRENCY FIELD')
          expect(page).to have_content('RADIO OPTION 1 RADIO FIELD')
          expect(page).to have_content('CHECKBOX OPTION 1 AND CHECK')
        end

        visit event_path(event)

        # expect(page).to still display the post-event format and not the form
        expect(page).to have_selector("#gender-graph")
        expect(page).to have_selector("#ethnicity-graph")
        expect(page).to have_selector("#age-graph")

        click_js_link 'Edit event data'

        fill_in 'Summary', with: 'Edited summary content'
        fill_in 'Impressions', with: '3333'
        fill_in 'Interactions', with: '222222'
        fill_in 'Samples', with: '4444444'

        click_button "Save"

        within ".box_metrics" do
          expect(page).to have_content('3,333')
          expect(page).to have_content('222,222')
          expect(page).to have_content('4,444,444')
        end

        expect(page).to have_content('Edited summary content')
      end

      scenario "should allow 0 for not required percentage fields" do
        campaign = FactoryGirl.create(:campaign, company: company)
        kpi = FactoryGirl.create(:kpi, kpi_type: 'percentage',
          kpis_segments: [ FactoryGirl.create(:kpis_segment, text: 'Male'),
                           FactoryGirl.create(:kpis_segment, text: 'Female') ] )

        campaign.add_kpi kpi

        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
          campaign: campaign )

        visit event_path(event)

        click_js_button "Save"

        expect(page).to have_no_content("The sum of the segments should be 100%")
      end

      scenario "should NOT allow 0 or less for the sum of required percentage fields" do
        campaign = FactoryGirl.create(:campaign, company: company)
        kpi = FactoryGirl.create(:kpi, kpi_type: 'percentage',
          kpis_segments: [ FactoryGirl.create(:kpis_segment, text: 'Male'),
                           FactoryGirl.create(:kpis_segment, text: 'Female') ] )

        field = campaign.add_kpi(kpi)
        field.options[:required] = 'true'
        field.save

        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
          campaign: campaign )

        visit event_path(event)

        click_js_button "Save"

        expect(find_field('Male')).to have_error('This field is required.')
        expect(find_field('Female')).to have_error('This field is required.')

        fill_in('Male', with: 35)
        fill_in('Female', with: 30)
        expect(page).to have_content("Field should sum 100%")

        within "#event-results-form" do
          expect(page).to have_content('65%')
        end

        fill_in('Female', with: 65)

        click_js_button "Save"

        expect(page).to have_no_content("Field should sum 100%")
      end

      scenario "the entered data should be saved automatically when submitting the event recap" do
        campaign = FactoryGirl.create(:campaign, company: company)
        kpi = FactoryGirl.create(:kpi, name: 'Test Field', kpi_type: 'number', capture_mechanism: 'integer')

        campaign.add_kpi kpi

        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
          campaign: campaign )

        visit event_path(event)

        fill_in 'Test Field', with: '98765'

        click_js_link "submit"

        expect(page).to have_content("Your post event report has been submitted for approval.")
        expect(page).to have_content("98765 TEST FIELD")
      end

      scenario "should not submit the event data if there are validation errors" do
        campaign = FactoryGirl.create(:campaign, company: company)
        kpi = FactoryGirl.create(:kpi, name: 'Test Field', kpi_type: 'number', capture_mechanism: 'integer')

        field = campaign.add_kpi(kpi)
        field.options[:required] = 'true'
        field.save

        event = FactoryGirl.create(:event,
          start_date: Date.yesterday.to_s(:slashes), end_date: Date.yesterday.to_s(:slashes),
          campaign: campaign )

        visit event_path(event)

        click_js_link "submit"

        expect(find_field('Test Field')).to have_error('This field is required.')

        expect(page).to have_no_content("Your post event report has been submitted for approval.")
      end

      scenario 'should not display the activities section if the campaigns have no activity types assigned' do
        visit event_path(event)
        expect(page).to have_no_selector('h3', text: 'ACTIVITIES')

        campaign.activity_types << FactoryGirl.create(:activity_type, company: company)

        visit event_path(event)
        expect(page).to have_selector('h3', text: 'ACTIVITIES')
      end

      scenario 'allows the user to add an activity to an Event, see it displayed in the Activities list and then deactivate it' do
        FactoryGirl.create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
        brand1 = FactoryGirl.create(:brand, name: 'Brand #1')
        brand2 = FactoryGirl.create(:brand, name: 'Brand #2')
        FactoryGirl.create(:marque, name: 'Marque #1 for Brand #2', brand: brand2)
        FactoryGirl.create(:marque, name: 'Marque #2 for Brand #2', brand: brand2)
        FactoryGirl.create(:marque, name: 'Marque alone', brand: brand1)
        campaign.brands << brand1
        campaign.brands << brand2

        activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
        FactoryGirl.create(:form_field, name: 'Brand', type: 'FormField::Brand', fieldable: activity_type, ordering: 1)
        FactoryGirl.create(:form_field, name: 'Marque', type: 'FormField::Marque', fieldable: activity_type, ordering: 2, settings: {'multiple' => true})
        FactoryGirl.create(:form_field, name: 'Form Field #1', type: 'FormField::Number', fieldable: activity_type, ordering: 3)
        dropdown_field = FactoryGirl.create(:form_field, name: 'Form Field #2', type: 'FormField::Dropdown', fieldable: activity_type, ordering: 4)
        FactoryGirl.create(:form_field_option, name: 'Dropdown option #1', form_field: dropdown_field, ordering: 1)
        FactoryGirl.create(:form_field_option, name: 'Dropdown option #2', form_field: dropdown_field, ordering: 2)

        campaign.activity_types << activity_type

        visit event_path(event)

        expect(page).to_not have_content('Activity Type #1')

        click_js_link('New Activity')

        within visible_modal do
          select_from_chosen('Activity Type #1', from: 'Activity type')
          select_from_chosen('Brand #2', from: 'Brand')
          wait_for_ajax
          select2("Marque #1 for Brand #2", from: "Marque")
          fill_in 'Form Field #1', with: '122'
          select_from_chosen('Dropdown option #2', from: 'Form Field #2')
          select_from_chosen('Juanito Bazooka', from: 'User')
          fill_in 'Date', with: '05/16/2013'
          click_js_button 'Create'
        end

        ensure_modal_was_closed

        within('#activities-list li') do
          expect(page).to have_content('Juanito Bazooka')
          expect(page).to have_content('THU May 16')
          expect(page).to have_content('Activity Type #1')
          click_js_link('Deactivate')
        end

        confirm_prompt 'Are you sure you want to deactivate this activity?'

        within("#activities-list") do
          expect(page).to have_no_selector('li')
        end
      end

      scenario 'allows the user to edit an activity from an Event' do
        FactoryGirl.create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
        brand = FactoryGirl.create(:brand, name: 'Unique Brand')
        FactoryGirl.create(:marque, name: 'Marque #1 for Brand', brand: brand)
        FactoryGirl.create(:marque, name: 'Marque #2 for Brand', brand: brand)
        campaign.brands << brand

        activity_type = FactoryGirl.create(:activity_type, name: 'Activity Type #1', company: company)
        campaign.activity_types << activity_type

        activity = FactoryGirl.create(:activity,
          activity_type: activity_type,
          activitable: event,
          campaign: campaign,
          company_user: company_user,
          activity_date: "08/21/2014"
        )

        visit event_path(event)

        hover_and_click("#activities-list #activity_#{activity.id}", 'Edit')

        within visible_modal do
          select_from_chosen('Juanito Bazooka', from: 'User')
          fill_in 'Date', with: '05/16/2013'
          click_js_button 'Save'
        end

        ensure_modal_was_closed

        within('#activities-list li') do
          expect(page).to have_content('Juanito Bazooka')
          expect(page).to have_content('THU May 16')
          expect(page).to have_content('Activity Type #1')
        end
      end
    end
  end

  def event_list_item(event)
    "li#event_#{event.id}"
  end

  def add_permissions(permissions)
    permissions.each do |p|
      company_user.role.permissions.create({action: p[0], subject_class: p[1]}, without_protection: true)
    end
  end
end