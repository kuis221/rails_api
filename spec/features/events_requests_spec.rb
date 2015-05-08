require 'rails_helper'

feature 'Events section' do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company, name: 'Campaign FY2012', brands: [brand]) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }
  let(:event) { create(:event, campaign: campaign, company: company) }
  let(:brand) { create(:brand, company: company, name: 'My Kool Brand') }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end

  after { Warden.test_reset! }

  shared_examples_for 'a user that can activate/deactivate events' do
    let(:events)do
      [
        create(:event, start_date: '08/21/2013', end_date: '08/21/2013',
                       start_time: '10:00am', end_time: '11:00am', campaign: campaign, place: place),
        create(:event, start_date: '08/28/2013', end_date: '08/29/2013',
                       start_time: '11:00am', end_time: '12:00pm', campaign: campaign, place: place)
      ]
    end
    scenario 'should allow user to deactivate events from the event list' do
      Timecop.travel(Time.zone.local(2013, 07, 30, 12, 01)) do
        events  # make sure events are created before
        Sunspot.commit
        visit events_path

        expect(page).to have_selector event_list_item(events.first)
        within resource_item events.first do
          click_js_button 'Deactivate Event'
        end

        confirm_prompt 'Are you sure you want to deactivate this event?'

        expect(page).to have_no_selector event_list_item(events.first)
      end
    end

    scenario 'should allow user to activate events' do
      Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
        events.each(&:deactivate!) # Deactivate the events
        Sunspot.commit

        visit events_path

        # Show only inactive items
        add_filter('ACTIVE STATE', 'Inactive')
        remove_filter('Active')

        expect(page).to have_selector event_list_item(events.first)
        within resource_item events.first do
          click_js_button 'Activate Event'
        end
        expect(page).to have_no_selector event_list_item(events.first)
      end
    end

    scenario 'allows the user to activate/deactivate a event from the event details page' do
      visit event_path(events.first)
      within('.edition-links') do
        click_js_button 'Deactivate Event'
      end

      confirm_prompt 'Are you sure you want to deactivate this event?'

      within('.edition-links') do
        click_js_button('Activate Event')
        expect(page).to have_button('Deactivate Event') # test the link have changed
      end
    end
  end

  feature 'non admin user', js: true, search: true do
    let(:role) { create(:non_admin_role, company: company) }

    it_should_behave_like 'a user that can activate/deactivate events' do
      before { company_user.campaigns << campaign }
      before { company_user.places << create(:place, city: nil, state: 'San Jose', country: 'CR', types: ['locality']) }
      let(:permissions) { [[:index, 'Event'], [:view_list, 'Event'], [:deactivate, 'Event'], [:show, 'Event']] }
    end
  end

  feature 'admin user', js: true, search: true do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can activate/deactivate events'

    feature '/events', js: true, search: true  do
      after do
        Timecop.return
      end

      feature 'Close bar' do
        let(:events)do
          [
            create(:submitted_event,
                   start_date: '08/21/2013', end_date: '08/21/2013',
                   campaign: create(:campaign, name: 'Campaign #1 FY2012', company: company)),
            create(:submitted_event,
                   start_date: '08/28/2013', end_date: '08/29/2013',
                   campaign: create(:campaign, name: 'Campaign #2 FY2012', company: company)),
            create(:submitted_event,
                   start_date: '08/28/2013', end_date: '08/29/2013',
                   campaign: create(:campaign, name: 'Campaign #3 FY2012', company: company)),
            create(:event, campaign: create(:campaign, name: 'Campaign #4 FY2012', company: company))
          ]
        end

        scenario 'Close bar should return the list of events' do
          events  # make sure users are created before
          Sunspot.commit
          visit events_path

          expect(page).to have_selector('#events-list .resource-item', count: 1)
          add_filter 'EVENT STATUS', 'Submitted'
          remove_filter 'Today To The Future'
          expect(page).to have_selector('#events-list .resource-item', count: 3)

          within resource_item(2) do
            click_js_link 'Event Details'
          end

          expect(page).to have_selector('h2', text: 'Campaign #2 FY2012')

          find('#resource-close-details').click
          expect(page).to have_selector('#events-list .resource-item', count: 2)
        end
      end

      feature 'GET index' do
        let(:events) do
          [
            create(:event,
                   start_date: '08/21/2013', end_date: '08/21/2013',
                   start_time: '10:00am', end_time: '11:00am',
                   campaign: campaign, active: true,
                   place: create(:place, name: 'Place 1')),
            create(:event,
                   start_date: '08/28/2013', end_date: '08/29/2013',
                   start_time: '11:00am', end_time: '12:00pm',
                   campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                   place: create(:place, name: 'Place 2'), company: company)
          ]
        end

        scenario 'a user can play and dismiss the video tutorial' do
          visit events_path

          feature_name = 'GETTING STARTED: EVENTS'

          expect(page).to have_selector('h5', text: feature_name)
          expect(page).to have_content('The Events module is your one-stop-shop')
          click_link 'Play Video'

          within visible_modal do
            click_js_link 'Close'
          end
          ensure_modal_was_closed

          within('.new-feature') do
            click_js_link 'Dismiss'
          end
          wait_for_ajax

          visit events_path
          expect(page).to have_no_selector('h5', text: feature_name)
        end

        scenario 'should display a list of events' do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            events  # make sure events are created before
            Sunspot.commit
            visit events_path

            # First Row
            within resource_item 1 do
              expect(page).to have_content('WED Aug 21')
              expect(page).to have_content('10:00 AM - 11:00 AM')
              expect(page).to have_content(events[0].place_name)
              expect(page).to have_content('Campaign FY2012')
            end
            # Second Row
            within resource_item 2  do
              expect(page).to have_content(events[1].start_at.strftime('WED Aug 28 at 11:00 AM'))
              expect(page).to have_content(events[1].end_at.strftime('THU Aug 29 at 12:00 PM'))
              expect(page).to have_content(events[1].place_name)
              expect(page).to have_content('Another Campaign April 03')
            end
          end
        end

        scenario 'user can remove the date filter tag' do
          place = create(:place, name: 'Place 1', city: 'Los Angeles', state: 'CA', country: 'US')
          create(:late_event, campaign: campaign, place: place)
          Sunspot.commit

          visit events_path

          expect(page).to have_content('0 events found for: Active Today To The Future')

          expect(collection_description).to have_filter_tag('Today To The Future')
          remove_filter 'Today To The Future'

          expect(page).to have_content('1 event found for: Active')
          expect(collection_description).not_to have_filter_tag('Today To The Future')

          within resource_item do
            expect(page).to have_content(campaign.name)
          end
        end

        scenario 'event should not be removed from the list when deactivated' do
          place = create(:place, name: 'Place 1', city: 'Los Angeles', state: 'CA', country: 'US')
          create(:event, campaign: campaign, place: place)
          Sunspot.commit

          visit events_path

          expect(page).to have_content('1 event found for: Active Today To The Future')
          add_filter 'ACTIVE STATE', 'Inactive'

          within resource_item do
            click_js_button 'Deactivate Event'
          end
          confirm_prompt 'Are you sure you want to deactivate this event?'

          expect(page).to have_button 'Activate Event'

          within resource_item do
            click_js_button 'Activate Event'
          end

          expect(page).to have_button 'Deactivate Event'

          remove_filter 'Inactive'
          within(events_list) { expect(page).to have_content(campaign.name) }
          within resource_item do
            click_js_button 'Deactivate Event'
          end
          confirm_prompt 'Are you sure you want to deactivate this event?'

          within(events_list) { expect(page).not_to have_content(campaign.name) }

          remove_filter 'Active'
          within(events_list) { expect(page).to have_content(campaign.name) }
        end

        scenario 'should allow allow filter events by date range selected from the calendar' do
          today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
          tomorrow = today + 1.day
          Timecop.travel(today) do
            create(:event,
                   start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                   start_time: '10:00am', end_time: '11:00am', campaign: campaign,
                   place: create(:place, name: 'Place 1', city: 'Los Angeles', state: 'CA', country: 'US'))
            create(:event,
                   start_date: tomorrow.to_s(:slashes), end_date: tomorrow.to_s(:slashes),
                   start_time: '11:00am',  end_time: '12:00pm',
                   campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                   place: create(:place, name: 'Place 2', city: 'Austin', state: 'TX', country: 'US'))
            Sunspot.commit

            visit events_path

            expect(page).to have_content('2 events found for: Active Today To The Future')

            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
            end

            expect(page).to have_filter_section(title: 'CAMPAIGNS',
                                                options: ['Campaign FY2012', 'Another Campaign April 03'])
            # expect(page).to have_filter_section(title: 'LOCATIONS', options: ['Los Angeles', 'Austin'])

            add_filter 'CAMPAIGNS', 'Campaign FY2012'

            expect(page).to have_content('1 event found for: Active Today To The Future Campaign FY2012')

            within events_list do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            add_filter 'CAMPAIGNS', 'Another Campaign April 03'
            within events_list do
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            expect(page).to have_content('2 events found for: Active Today To The Future Another Campaign April 03 Campaign FY2012')

            select_filter_calendar_day('18')
            within events_list do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end

            expect(page).to have_content('1 event found for: Active Today Another Campaign April 03 Campaign FY2012')

            select_filter_calendar_day('18', '19')
            expect(page).to have_content(
              '2 events found for: Active Today - Tomorrow Another Campaign April 03 Campaign FY2012'
            )
            within events_list do
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end
          end
        end

        feature 'export' do
          let(:month_number) { today.strftime('%m') }
          let(:month_name) { today.strftime('%b') }
          let(:year_number) { today.strftime('%Y').to_i }
          let(:today) { Time.use_zone(user.time_zone) { Time.current } }
          let(:event1) do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                           start_time: '10:00am', end_time: '11:00am',
                           campaign: campaign, active: true,
                           place: create(:place, name: 'Place 1'))
          end
          let(:event2) do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                           start_time: '08:00am', end_time: '09:00am',
                           campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                           place: create(:place, name: 'Place 2', city: 'Los Angeles',
                                                 state: 'CA', zipcode: '67890'))
          end

          before do
            # make sure events are created before
            event1
            event2
            Sunspot.commit
          end

          scenario 'should be able to export as xls' do
            contact1 = create(:contact, first_name: 'Guillermo', last_name: 'Vargas', email: 'guilleva@gmail.com', company: company)
            contact2 = create(:contact, first_name: 'Chris', last_name: 'Jaskot', email: 'cjaskot@gmail.com', company: company)
            create(:contact_event, event: event1, contactable: contact1)
            create(:contact_event, event: event1, contactable: contact2)
            Sunspot.commit

            visit events_path

            click_js_link 'Download'
            click_js_link 'Download as XLS'

            within visible_modal do
              expect(page).to have_content('We are processing your request, the download will start soon...')
              expect(ListExportWorker).to have_queued(ListExport.last.id)
              ResqueSpec.perform_all(:export)
            end

            ensure_modal_was_closed
            expect(ListExport.last).to have_rows([
              ['CAMPAIGN NAME', 'AREA', 'START', 'END', 'DURATION', 'VENUE NAME', 'ADDRESS', 'CITY',
               'STATE', 'ZIP', 'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL'],
              ['Another Campaign April 03', nil, "#{year_number}-#{month_number}-#{today.strftime('%d')}T08:00",
               "#{year_number}-#{month_number}-#{today.strftime('%d')}T09:00", '1.00', 'Place 2',
               'Place 2, 11 Main St., Los Angeles, CA, 67890', 'Los Angeles', 'CA', '67890', 'Active', 'Unsent',
               nil, nil, "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/events/#{event2.id}"],
              ['Campaign FY2012', nil, "#{year_number}-#{month_number}-#{today.strftime('%d')}T10:00",
               "#{year_number}-#{month_number}-#{today.strftime('%d')}T11:00", '1.00', 'Place 1',
               'Place 1, 11 Main St., New York City, NY, 12345', 'New York City', 'NY', '12345', 'Active',
               'Unsent', nil, 'Chris Jaskot, Guillermo Vargas',
               "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/events/#{event1.id}"]
            ])
          end

          scenario 'should be able to export as PDF' do
            visit events_path

            click_js_link 'Download'
            click_js_link 'Download as PDF'

            within visible_modal do
              expect(page).to have_content('We are processing your request, the download will start soon...')
              export = ListExport.last
              expect(ListExportWorker).to have_queued(export.id)
              ResqueSpec.perform_all(:export)
            end
            ensure_modal_was_closed

            export = ListExport.last
            # Test the generated PDF...
            reader = PDF::Reader.new(open(export.file.url))
            reader.pages.each do |page|
              # PDF to text seems to not always return the same results
              # with white spaces, so, remove them and look for strings
              # without whitespaces
              text = page.text.gsub(/[\s\n]/, '')
              expect(text).to include '2eventsfoundfor:'
              expect(text).to include 'CampaignFY2012'
              expect(text).to include 'AnotherCampaignApril03'
              expect(text).to include 'NewYorkCity,NY,12345'
              expect(text).to include 'LosAngeles,CA,67890'
              expect(text).to include '10:00AM-11:00AM'
              expect(text).to include '8:00AM-9:00AM'
              expect(text).to match(/#{month_name}#{today.strftime('%-d')}/)
            end
          end

          scenario 'should be able to export the calendar view as PDF' do
            visit events_path

            click_link 'Calendar View'

            expect(find('.calendar-table')).to have_text 'My Kool Brand'

            click_js_link 'Download'
            click_js_link 'Download as PDF'

            within visible_modal do
              expect(page).to have_content('We are processing your request, the download will start soon...')
              export = ListExport.last
              expect(ListExportWorker).to have_queued(export.id)
              ResqueSpec.perform_all(:export)
            end
            ensure_modal_was_closed

            export = ListExport.last
            # Test the generated PDF...
            reader = PDF::Reader.new(open(export.file.url))
            reader.pages.each do |page|
              # PDF to text seems to not always return the same results
              # with white spaces, so, remove them and look for strings
              # without whitespaces
              text = page.text.gsub(/[\s\n]/, '')
              expect(text).to include 'MyKool'
              expect(text).to include "#{today.strftime('%B')}#{year_number}"
            end
          end

          scenario 'event list export is limited to 200 pages' do
            allow(Event).to receive(:do_search).and_return(double(total: 3000))

            visit events_path

            click_js_link 'Download'
            click_js_link 'Download as PDF'

            within visible_modal do
              expect(page).to have_content('PDF exports are limited to 200 pages. Please narrow your results and try exporting again.')
              click_js_link 'OK'
            end
            ensure_modal_was_closed
          end
        end

        feature 'date ranges box' do
          let(:today) { Time.zone.local(Time.now.year, Time.now.month, Time.now.day, 12, 00) }
          let(:month_number) { Time.now.strftime('%m').to_i }
          let(:year) { Time.now.strftime('%Y').to_i }
          let(:campaign1) { create(:campaign, name: 'Campaign FY2012', company: company) }
          let(:campaign2) { create(:campaign, name: 'Another Campaign April 03', company: company) }
          let(:campaign3) { create(:campaign, name: 'New Brand Campaign', company: company) }

          scenario "can filter the events by predefined 'Today' date range option" do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign1)
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign2)
            create(:event, start_date: (today + 1.day).to_s(:slashes), end_date: (today + 1.day).to_s(:slashes), campaign: campaign3)
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Today'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 2)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_no_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'Current week' date range option" do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign2)
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign3)
            create(:event, start_date: (today - 2.weeks).to_s(:slashes), end_date: (today - 2.weeks).to_s(:slashes), campaign: campaign1)
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Current week'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 2)
            within events_list do
              expect(page).to have_no_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'Current month' date range option" do
            create(:event, campaign: campaign3,
                           start_date: "#{month_number}/15/#{year}",
                           end_date: "#{month_number}/15/#{year}")
            create(:event, campaign: campaign2,
                           start_date: "#{month_number}/16/#{year}",
                           end_date: "#{month_number}/16/#{year}")
            create(:event, campaign: campaign1,
                           start_date: "#{(today + 1.month).month}/15/#{(today + 1.month).year}",
                           end_date: "#{(today + 1.month).month}/15/#{(today + 1.month).year}")
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Current month'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 2)
            within events_list do
              expect(page).to have_no_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'Previous week' date range option" do
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign2)
            create(:event, start_date: today.to_s(:slashes), end_date: today.to_s(:slashes), campaign: campaign3)
            create(:event, start_date: (today - 1.week).to_s(:slashes), end_date: (today - 1.week).to_s(:slashes), campaign: campaign1)
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Previous week'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 1)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_no_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'Previous month' date range option" do
            create(:event, campaign: campaign2,
                           start_date: "#{month_number}/15/#{year}",
                           end_date: "#{month_number}/15/#{year}")
            create(:event, campaign: campaign1,
                           start_date: "#{(today - 1.month).month}/15/#{(today - 1.month).year}",
                           end_date: "#{(today - 1.month).month}/15/#{(today - 1.month).year}")
            create(:event, campaign: campaign1,
                           start_date: "#{(today - 1.month).month}/16/#{(today - 1.month).year}",
                           end_date: "#{(today - 1.month).month}/16/#{(today - 1.month).year}")
            create(:event, campaign: campaign3,
                           start_date: "#{(today - 1.month).month}/17/#{(today - 1.month).year}",
                           end_date: "#{(today - 1.month).month}/17/#{(today - 1.month).year}")
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'Previous month'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 3)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'YTD' date range option for default YTD configuration" do
            create(:event, campaign: campaign1,
                           start_date: "01/01/#{year}",
                           end_date: "01/01/#{year}")
            create(:event, campaign: campaign1,
                           start_date: "01/01/#{year}",
                           end_date: "01/01/#{year}")
            create(:event, campaign: campaign2,
                           start_date: "01/01/#{year}",
                           end_date: "01/01/#{year}")
            create(:event, campaign: campaign3,
                           start_date: "07/17/#{year - 1}",
                           end_date: "07/17/#{year - 1}")
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'YTD'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 3)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_no_content('New Brand Campaign')
            end
          end

          scenario "can filter the events by predefined 'YTD' date range option where YTD goes from July 1 to June 30" do
            company.update_attribute(:ytd_dates_range, Company::YTD_JULY1_JUNE30)
            user.current_company = company

            create(:event, campaign: campaign1,
                           start_date: "#{month_number}/01/#{year}",
                           end_date: "#{month_number}/01/#{year}")
            create(:event, campaign: campaign1,
                           start_date: "#{month_number}/01/#{year}",
                           end_date: "#{month_number}/01/#{year}")
            create(:event, campaign: campaign3,
                           start_date: "#{month_number}/01/#{year}",
                           end_date: "#{month_number}/01/#{year}")
            Sunspot.commit

            visit events_path

            choose_predefined_date_range 'YTD'
            wait_for_ajax

            expect(page).to have_selector('#events-list .resource-item', count: 3)
            within events_list do
              expect(page).to have_content('Campaign FY2012')
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end

          scenario 'can filter the events by custom date range selecting start and end dates' do
            create(:event,
                   campaign: campaign1,
                   start_date: (today - 2.weeks).to_s(:slashes),
                   end_date: (today - 2.weeks).to_s(:slashes))
            create(:event, campaign: campaign2,
                           start_date: today.to_s(:slashes), end_date: today.to_s(:slashes))
            create(:event, campaign: campaign2,
                           start_date: Date.today.beginning_of_week.to_s(:slashes),
                           end_date: Date.today.beginning_of_week.to_s(:slashes))
            create(:event, campaign: campaign3,
                           start_date: today.to_s(:slashes), end_date: today.to_s(:slashes))
            create(:event, campaign: campaign3,
                           start_date: (Date.today.beginning_of_week + 5.days).to_s(:slashes),
                           end_date: (Date.today.beginning_of_week + 5.days).to_s(:slashes))
            Sunspot.commit

            visit events_path

            click_js_link 'Date ranges'

            within 'ul.dropdown-menu' do
              expect(page).to have_button('Apply', disabled: true)
              find_field('Start date').click
              select_and_fill_from_datepicker('custom_start_date', Date.today.beginning_of_week.to_s(:slashes))
              find_field('End date').click
              select_and_fill_from_datepicker('custom_end_date', (Date.today.beginning_of_week + 5.days).to_s(:slashes))
              expect(page).to have_button('Apply', disabled: false)
              click_js_button 'Apply'
            end
            ensure_date_ranges_was_closed

            expect(page).to have_selector('#events-list .resource-item', count: 4)
            within events_list do
              expect(page).to have_no_content('Campaign FY2012')
              expect(page).to have_content('Another Campaign April 03')
              expect(page).to have_content('New Brand Campaign')
            end
          end
        end

        scenario 'can filter by users' do
          ev1 = create(:event,
                       campaign: create(:campaign, name: 'Campaña1', company: company))
          ev2 = create(:event,
                       campaign: create(:campaign, name: 'Campaña2', company: company))
          ev1.users << create(:company_user,
                              user: create(:user, first_name: 'Roberto', last_name: 'Gomez'),
                              company: company)
          ev2.users << create(:company_user,
                              user: create(:user, first_name: 'Mario', last_name: 'Cantinflas'),
                              company: company)
          Sunspot.commit

          visit events_path

          expect(page).to have_filter_section(
            title: 'PEOPLE',
            options: ['Mario Cantinflas', 'Roberto Gomez', user.full_name])

          within events_list do
            expect(page).to have_content('Campaña1')
            expect(page).to have_content('Campaña2')
          end

          add_filter 'PEOPLE', 'Roberto Gomez'

          within events_list do
            expect(page).to have_content('Campaña1')
            expect(page).to have_no_content('Campaña2')
          end

          remove_filter 'Roberto Gomez'
          add_filter 'PEOPLE', 'Mario Cantinflas'

          within events_list do
            expect(page).to have_content('Campaña2')
            expect(page).to have_no_content('Campaña1')
          end
        end

        scenario 'Filters are preserved upon navigation' do
          today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
          tomorrow = today + 1.day
          Timecop.travel(today) do
            ev1 = create(:event, campaign: campaign,
                                 start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                                 start_time: '10:00am', end_time: '11:00am',
                                 place: create(:place, name: 'Place 1', city: 'Los Angeles',
                                                       state: 'CA', country: 'US'))

            create(:event,
                   start_date: tomorrow.to_s(:slashes), end_date: tomorrow.to_s(:slashes),
                   start_time: '11:00am',  end_time: '12:00pm',
                   campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                   place: create(:place, name: 'Place 2', city: 'Austin', state: 'TX', country: 'US'))
            Sunspot.commit

            visit events_path

            add_filter 'CAMPAIGNS', 'Campaign FY2012'
            select_filter_calendar_day('18')

            within events_list do
              click_js_link('Event Details')
            end

            expect(page).to have_selector('h2', text: 'Campaign FY2012')
            expect(current_path).to eq(event_path(ev1))

            close_resource_details

            expect(page).to have_content('1 event found for: Active Today Campaign FY2012')
            expect(current_path).to eq(events_path)

            within events_list do
              expect(page).to have_no_content('Another Campaign April 03')
              expect(page).to have_content('Campaign FY2012')
            end
          end
        end

        scenario 'first filter should keep default filters' do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            create(:event, campaign: campaign,
                           start_date: '07/07/2013', end_date: '07/07/2013')
            create(:event, campaign: campaign,
                           start_date: '07/21/2013', end_date: '07/21/2013')
            Sunspot.commit

            visit events_path

            expect(page).to have_content('1 event found for: Active Today To The Future')
            expect(page).to have_selector('#events-list .resource-item', count: 1)

            add_filter 'CAMPAIGNS', 'Campaign FY2012'
            expect(page).to have_content('1 event found for: Active Today To The Future Campaign FY2012')  # The list shouldn't be filtered by date
            expect(page).to have_selector('#events-list .resource-item', count: 1)
          end
        end

        scenario 'reset filter set the filter options to its initial state' do
          Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
            create(:event, campaign: campaign, start_date: '07/11/2013', end_date: '07/11/2013')
            create(:event, campaign: campaign, start_date: '07/21/2013', end_date: '07/21/2013')

            create(:custom_filter,
                   owner: company_user, name: 'My Custom Filter', apply_to: 'events',
                   filters:  'status%5B%5D=Active')

            Sunspot.commit

            visit events_path
            expect(page).to have_content('1 event found for: Active Today To The Future')
            expect(page).to have_selector('#events-list .resource-item', count: 1)

            expect(page).to have_content('1 event found for: Active Today To The Future')

            select_saved_filter 'My Custom Filter'

            expect(page).to have_content('2 events found for: My Custom Filter')

            add_filter 'CAMPAIGNS', 'Campaign FY2012'
            expect(page).to have_content('2 events found for: Campaign FY2012 My Custom Filter')

            click_button 'Reset'
            expect(page).to have_content('1 event found for: Active Today To The Future')

            within '#collection-list-filters' do
              expect(find_field('user-saved-filter', visible: false).value).to eq('')
            end

            expect(page).to have_selector('#events-list .resource-item', count: 1)
            add_filter 'CAMPAIGNS', 'Campaign FY2012'

            expect(page).to have_content('1 event found for: Active Today To The Future Campaign FY2012')
            expect(page).to have_selector('#events-list .resource-item', count: 1)

            remove_filter 'Today To The Future'
            expect(page).to have_content('2 events found for: Active Campaign FY2012')
            expect(page).to have_selector('#events-list .resource-item', count: 2)

            click_link 'Reset'
            expect(page).to have_content('1 event found for: Active Today To The Future')
          end
        end

        feature 'with timezone support turned ON' do
          before do
            company.update_column(:timezone_support, true)
            user.reload
          end
          scenario "should display the dates relative to event's timezone" do
            Timecop.travel(Time.zone.local(2013, 07, 21, 12, 01)) do
              # Create a event with the time zone "Central America"
              Time.use_zone('Central America') do
                create(:event, company: company,
                               start_date: '08/21/2013', end_date: '08/21/2013',
                               start_time: '10:00am', end_time: '11:00am')
              end

              # Just to make sure the current user is not in the same timezone
              expect(user.time_zone).to eq('Pacific Time (US & Canada)')

              Sunspot.commit
              visit events_path

              within resource_item 1 do
                expect(page).to have_content('WED Aug 21')
                expect(page).to have_content('10:00 AM - 11:00 AM')
              end
            end
          end
        end

        feature 'filters' do

          it_behaves_like 'a list that allow saving custom filters' do

            before do
              create(:campaign, name: 'Campaign 1', company: company)
              create(:campaign, name: 'Campaign 2', company: company)
              create(:area, name: 'Area 1', company: company)
            end

            let(:list_url) { events_path }

            let(:filters) do
              [{ section: 'CAMPAIGNS', item: 'Campaign 1' },
               { section: 'CAMPAIGNS', item: 'Campaign 2' },
               { section: 'AREAS',     item: 'Area 1' },
               { section: 'ACTIVE STATE', item: 'Inactive' }]
            end
          end

          scenario 'Users must be able to filter on all brands they have permissions to access ' do
            today = Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00)
            tomorrow = today + 1.day
            Timecop.travel(today) do
              ev1 = create(:event,
                           start_date: today.to_s(:slashes), end_date: today.to_s(:slashes),
                           start_time: '10:00am', end_time: '11:00am',
                           campaign: campaign,
                           place: create(:place, name: 'Place 1', city: 'Los Angeles', state: 'CA', country: 'US'))
              ev2 = create(:event,
                           start_date: tomorrow.to_s(:slashes), end_date: tomorrow.to_s(:slashes),
                           start_time: '11:00am',  end_time: '12:00pm',
                           campaign: create(:campaign, name: 'Another Campaign April 03', company: company),
                           place: create(:place, name: 'Place 2', city: 'Austin', state: 'TX', country: 'US'))
              brands = [
                create(:brand, name: 'Cacique', company: company),
                create(:brand, name: 'Smirnoff', company: company)
              ]
              create(:brand, name: 'Centenario')  # Brand not added to the user/campaing
              ev1.campaign.brands << brands.first
              ev2.campaign.brands << brands.last
              company_user.brands << brands
              Sunspot.commit
              visit events_path

              expect(page).to have_filter_section(title: 'BRANDS', options: %w(Cacique Smirnoff))

              within events_list do
                expect(page).to have_content('Campaign FY2012')
                expect(page).to have_content('Another Campaign April 03')
              end

              add_filter 'BRANDS', 'Cacique'

              within events_list do
                expect(page).to have_content('Campaign FY2012')
                expect(page).to have_no_content('Another Campaign April 03')
              end
              remove_filter 'Cacique'
              add_filter 'BRANDS', 'Smirnoff'

              within events_list do
                expect(page).to have_no_content('Campaign FY2012')
                expect(page).to have_content('Another Campaign April 03')
              end
            end
          end

          scenario 'Users must be able to filter on all areas they have permissions to access ' do
            areas = [
              create(:area, name: 'Gran Area Metropolitana',
                            description: 'Ciudades principales de Costa Rica', company: company),
              create(:area, name: 'Zona Norte',
                            description: 'Ciudades del Norte de Costa Rica', company: company),
              create(:area, name: 'Inactive Area', active: false,
                            description: 'This should not appear', company: company)
            ]
            areas.each do |area|
              company_user.areas << area
            end
            Sunspot.commit

            visit events_path

            expect(page).to have_filter_section(title: 'AREAS',
                                                options: ['Gran Area Metropolitana', 'Zona Norte'])
          end
        end
      end
    end

    feature 'custom filters' do
      let(:campaign1) { create(:campaign, name: 'Campaign 1', company: company) }
      let(:campaign2) { create(:campaign, name: 'Campaign 2', company: company) }
      let(:event1) { create(:submitted_event, campaign: campaign1) }
      let(:event2) { create(:late_event, campaign: campaign2) }
      let(:user1) { create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company) }
      let(:user2) { create(:company_user, user: create(:user, first_name: 'Mario', last_name: 'Moreno'), company: company) }

      scenario 'allows to apply custom filters' do
        event1.users << user1
        event2.users << user2
        Sunspot.commit

        create(:custom_filter,
               owner: company_user, name: 'Custom Filter 1', apply_to: 'events',
               filters: 'campaign%5B%5D=' + campaign1.to_param + '&user%5B%5D=' + user1.to_param +
                        '&event_status%5B%5D=Submitted&status%5B%5D=Active')
        create(:custom_filter,
               owner: company_user, name: 'Custom Filter 2', apply_to: 'events',
               filters: 'campaign%5B%5D=' + campaign2.to_param + '&user%5B%5D=' + user2.to_param +
                        '&event_status%5B%5D=Late&status%5B%5D=Active')

        visit events_path

        within events_list do
          expect(page).to have_content('Campaign 1')
          expect(page).to_not have_content('Campaign 2')
        end

        # Using Custom Filter 1
        select_saved_filter 'Custom Filter 1'

        within events_list do
          expect(page).to have_content('Campaign 1')
        end

        within '.form-facet-filters' do
          expect(find_field('Campaign 2')['checked']).to be_falsey
          expect(find_field('Mario Moreno')['checked']).to be_falsey
          expect(find_field('Late')['checked']).to be_falsey

          expect(collection_description).to have_filter_tag('Custom Filter 1')
          expect(page).not_to have_field('Custom Filter 1')

          expect(find_field('Inactive')['checked']).to be_falsey
        end

        # Using Custom Filter 2 should update results and checked/unchecked checkboxes
        select_saved_filter 'Custom Filter 2'

        # Should uncheck Custom Filter 1's params
        expect(collection_description).not_to have_filter_tag('Submitted')
        expect(collection_description).not_to have_filter_tag('Campaign 1')
        expect(collection_description).not_to have_filter_tag('Roberto Gomez')

        # Should have the Custom Filter 2's
        expect(collection_description).to have_filter_tag('Custom Filter 2')

        within events_list do
          expect(page).not_to have_content('Campaign 1')
          expect(page).to have_content('Campaign 2')
        end

        within '.form-facet-filters' do
          expect(page).to have_field('Campaign 1')
          expect(page).to have_field('Roberto Gomez')
          expect(page).to have_field('Submitted')
          expect(page).to have_field('Inactive')
          expect(page).not_to have_field('Custom Filter 2')
        end
      end
    end

    feature 'create a event' do
      scenario 'allows to create a new event' do
        create(:company_user,
               company: company,
               user: create(:user, first_name: 'Other', last_name: 'User'))
        create(:campaign, company: company, name: 'ABSOLUT Vodka')
        visit events_path

        click_button 'New Event'

        within visible_modal do
          expect(page).to have_content(company_user.full_name)
          select_from_chosen('ABSOLUT Vodka', from: 'Campaign')
          select_from_chosen('Other User', from: 'Event staff')
          fill_in 'Description', with: 'some event description'
          click_button 'Create'
        end
        ensure_modal_was_closed
        expect(page).to have_content('ABSOLUT Vodka')
        expect(page).to have_content('some event description')
        within '#event-team-members' do
          expect(page).to have_content('Other User')
        end
      end

      scenario 'end date are updated after user changes the start date' do
        Timecop.travel(Time.zone.local(2013, 07, 30, 12, 00)) do
          create(:campaign, company: company)
          visit events_path

          click_button 'New Event'

          within visible_modal do
            # Test both dates are the same
            expect(find_field('event_start_date').value).to eql '07/30/2013'
            expect(find_field('event_end_date').value).to eql '07/30/2013'

            # Change the start date and make sure the end date is changed automatically
            find_field('event_start_date').click
            find_field('event_start_date').set '07/29/2013'
            find_field('event_end_date').click
            expect(find_field('event_end_date').value).to eql '07/29/2013'

            # Now, change the end data to make them different and test that the difference
            # is kept after changing start date
            find_field('event_end_date').set '07/31/2013'
            find_field('event_start_date').click
            find_field('event_start_date').set '07/20/2013'
            find_field('event_end_date').click
            expect(find_field('event_end_date').value).to eql '07/22/2013'

            # Change the start time and make sure the end date is changed automatically
            # to one hour later
            find_field('event_start_time').click
            find_field('event_start_time').set '08:00am'
            find_field('event_end_time').click
            expect(find_field('event_end_time').value).to eql '9:00am'

            find_field('event_start_time').click
            find_field('event_start_time').set '4:00pm'
            find_field('event_end_time').click
            expect(find_field('event_end_time').value).to eql '5:00pm'
          end
        end
      end

      scenario 'end date are updated next day' do
        Timecop.travel(Time.zone.local(2013, 07, 30, 12, 00)) do
          create(:campaign, company: company)
          visit events_path

          click_button 'New Event'

          within visible_modal do
            # Test both dates are the same
            expect(find_field('event_start_date').value).to eql '07/30/2013'
            expect(find_field('event_end_date').value).to eql '07/30/2013'

            # Change the start time and make sure the end date is changed automatically
            # to one day later
            find_field('event_start_time').click
            find_field('event_start_time').set '11:00pm'
            find_field('event_end_time').click
            expect(find_field('event_end_date').value).to eql '07/31/2013'

            find_field('event_start_date').click
            find_field('event_start_date').set '07/31/2013'
            find_field('event_end_time').click
            find_field('event_end_time').set '2:00pm'
            find_field('event_end_time').click
            expect(find_field('event_end_date').value).to eql '08/01/2013'
          end
        end
      end
    end

    feature 'edit a event' do
      scenario 'allows to edit a event' do
        create(:campaign, company: company, name: 'ABSOLUT Vodka FY2013')
        create(:event,
               start_date: 3.days.from_now.to_s(:slashes),
               end_date: 3.days.from_now.to_s(:slashes),
               start_time: '8:00 PM', end_time: '11:00 PM',
               campaign: create(:campaign, name: 'ABSOLUT Vodka FY2012', company: company))
        Sunspot.commit

        visit events_path

        within resource_item do
          click_js_button 'Edit Event'
        end

        within visible_modal do
          expect(find_field('event_start_date').value).to eq(3.days.from_now.to_s(:slashes))
          expect(find_field('event_end_date').value).to eq(3.days.from_now.to_s(:slashes))
          expect(find_field('event_start_time').value).to eq('8:00pm')
          expect(find_field('event_end_time').value).to eq('11:00pm')

          select_from_chosen('ABSOLUT Vodka FY2013', from: 'Campaign')
          click_js_button 'Save'
        end
        ensure_modal_was_closed
        expect(page).to have_content('ABSOLUT Vodka FY2013')
      end

      feature 'with timezone support turned ON' do
        before do
          company.update_column(:timezone_support, true)
          user.reload
        end
        scenario "should display the dates relative to event's timezone" do
          date = 3.days.from_now.to_s(:slashes)
          Time.use_zone('America/Guatemala') do
            create(:event,
                   start_date: date, end_date: date,
                   start_time: '8:00 PM', end_time: '11:00 PM',
                   campaign: create(:campaign, name: 'ABSOLUT Vodka FY2012', company: company))
          end
          Sunspot.commit

          Time.use_zone('America/New_York') do
            visit events_path

            within resource_item do
              click_js_button 'Edit Event'
            end

            within visible_modal do
              expect(find_field('event_start_date').value).to eq(date)
              expect(find_field('event_end_date').value).to eq(date)
              expect(find_field('event_start_time').value).to eq('8:00pm')
              expect(find_field('event_end_time').value).to eq('11:00pm')

              fill_in('event_start_time', with: '10:00pm')
              fill_in('event_end_time', with: '11:00pm')

              click_button 'Save'
            end
            ensure_modal_was_closed
            expect(page).to have_content('10:00 PM - 11:00 PM')
          end

          # Check that the event's time is displayed with the same time in a different tiem zone
          Time.use_zone('America/Los_Angeles') do
            visit events_path
            within events_list do
              expect(page).to have_content('10:00 PM - 11:00 PM')
            end
          end
        end
      end
    end

    feature '/events/:event_id', js: true do
      scenario 'a user can play and dismiss the video tutorial (scheduled event)' do
        event = create(:event,
                       start_date: '08/28/2013', end_date: '08/28/2013',
                       start_time: '8:00 PM', end_time: '11:00 PM',
                       campaign: campaign)
        visit event_path(event)

        feature_name = 'GETTING STARTED: EVENT DETAILS'

        expect(page).to have_selector('h5', text: feature_name)
        expect(page).to have_content('Welcome to the Event Details page')
        click_link 'Play Video'

        within visible_modal do
          click_js_link 'Close'
        end
        ensure_modal_was_closed

        within('.new-feature') do
          click_js_link 'Dismiss'
        end
        wait_for_ajax

        visit event_path(event)
        expect(page).to have_no_selector('h5', text: feature_name)
      end

      scenario 'a user can play and dismiss the video tutorial (executed event)' do
        event = create(:approved_event,
                       start_date: '08/28/2013', end_date: '08/28/2013',
                       start_time: '8:00 PM', end_time: '11:00 PM',
                       campaign: campaign)
        visit event_path(event)

        feature_name = 'GETTING STARTED: EVENT DETAILS'

        expect(page).to have_selector('h5', text: feature_name)
        expect(page).to have_content('You are viewing the Event Details page for an executed event')
        click_link 'Play Video'

        within visible_modal do
          click_js_link 'Close'
        end
        ensure_modal_was_closed

        within('.new-feature') do
          click_js_link 'Dismiss'
        end
        wait_for_ajax

        visit event_path(event)
        expect(page).to have_no_selector('h5', text: feature_name)
      end

      scenario 'GET show should display the event details page' do
        event = create(:event, campaign: campaign,
                               start_date: '08/28/2013', end_date: '08/28/2013',
                               start_time: '8:00 PM', end_time: '11:00 PM')
        visit event_path(event)
        expect(page).to have_selector('h2', text: 'Campaign FY2012')
        within('.calendar-data') do
          expect(page).to have_content('WED Aug 28')
          expect(page).to have_content('8:00 PM - 11:00 PM')
        end
      end

      feature 'with timezone suport turned ON' do
        before do
          company.update_column(:timezone_support, true)
          user.reload
        end

        scenario "should display the dates relative to event's timezone" do
          # Create a event with the time zone "Central America"
          event = Time.use_zone('Central America') do
            create(:event, campaign: campaign,
                           start_date: '08/21/2013', end_date: '08/21/2013',
                           start_time: '10:00am', end_time: '11:00am')
          end

          # Just to make sure the current user is not in the same timezone
          expect(user.time_zone).to eq('Pacific Time (US & Canada)')

          visit event_path(event)

          within('.calendar-data') do
            expect(page).to have_content('WED Aug 21')
            expect(page).to have_content('10:00 AM - 11:00 AM')
          end
        end
      end

      scenario 'allows to add a user as contact to the event', js: true do
        create(:user, first_name: 'Pablo', last_name: 'Baltodano',
                      email: 'palinair@gmail.com', company_id: company.id,
                      role_id: company_user.role_id)
        Sunspot.commit

        visit event_path(event)

        click_js_button 'Add Contact'
        within visible_modal do
          fill_in 'contact-search-box', with: 'Pab'
          expect(page).to have_content('Pablo Baltodano')
          within resource_item do
            click_js_link('Add')
          end

          expect(page).to have_no_content('Pablo Baltodano')
        end
        close_modal

        # Test the user was added to the list of event members and it can be removed
        within '#event-contacts-list' do
          expect(page).to have_content('Pablo Baltodano')
          click_js_link 'Remove Contact'
        end

        # Refresh the page and make sure the user is not there
        visit event_path(event)

        expect(page).to_not have_content('Pablo Baltodano')
      end

      scenario 'allows to add a contact as contact to the event', js: true do
        create(:contact,
               first_name: 'Guillermo', last_name: 'Vargas',
               email: 'guilleva@gmail.com', company_id: company.id)
        Sunspot.commit

        visit event_path(event)

        click_js_button 'Add Contact'
        within visible_modal do
          fill_in 'contact-search-box', with: 'Gui'
          expect(page).to have_content('Guillermo Vargas')
          within resource_item do
            click_js_link 'Add'
          end

          expect(page).to have_no_content 'Guillermo Vargas'
        end
        close_modal

        # Test the user was added to the list of event members and it can be removed
        within '#event-contacts-list' do
          expect(page).to have_content('Guillermo Vargas')
          click_js_link 'Remove Contact'
        end

        # Refresh the page and make sure the user is not there
        visit event_path(event)

        expect(page).to_not have_content('Guillermo Vargas')
      end

      scenario 'allows to create a contact', js: true do
        visit event_path(event)

        click_js_button 'Add Contact'
        visible_modal.click_js_link('Create New Contact')

        within '.contactevent_modal' do
          fill_in 'First name', with: 'Pedro'
          fill_in 'Last name', with: 'Picapiedra'
          fill_in 'Email', with: 'pedro@racadura.com'
          fill_in 'Phone number', with: '+1 505 22343222'
          fill_in 'Address', with: 'ABC 123'
          select_from_chosen('United States of America', from: 'Country')
          select_from_chosen('California', from: 'State')
          fill_in 'City', with: 'Los Angeles'
          fill_in 'Zip code', with: '12345'
          click_js_button 'Save'
        end

        ensure_modal_was_closed

        # Test the contact was added to the list of event members and it can be removed
        within '#event-contacts-list' do
          expect(page).to have_content('Pedro Picapiedra')
        end

        # Test removal of the contact
        click_js_link 'Remove Contact'
        expect(page).to_not have_content('Pedro Picapiedra')

        # Refresh the page and make sure the contact is not there
        visit event_path(event)

        expect(page).to_not have_content('Pedro Picapiedra')
      end

      scenario 'allows to create a new task for the event and mark it as completed' do
        event = create(:event, campaign: create(:campaign, company: company))
        juanito = create(:user, company: company, first_name: 'Juanito', last_name: 'Bazooka')
        juanito_user = juanito.company_users.first
        event.users << juanito_user
        event.users << user.company_users.first
        Sunspot.commit

        visit event_path(event)

        click_js_button 'Add Task'
        within('form#new_task') do
          fill_in 'Title', with: 'Pick up the kidz at school'
          fill_in 'Due at', with: '05/16/2013'
          select_from_chosen('Juanito Bazooka', from: 'Assigned To')
          click_js_button 'Submit'
        end

        within resource_item list: '#tasks-list' do
          expect(page).to have_content('Pick up the kidz at school')
          expect(page).to have_content('Juanito Bazooka')
          expect(page).to have_content('THU May 16')
        end

        # Mark the tasks as completed
        within('#event-tasks') do
          checkbox = find('.task-completed-checkbox', visible: :false)
          expect(checkbox['checked']).to be_falsey
          find('.task-completed-checkbox').trigger('click')
          wait_for_ajax

          # refresh the page to make sure the checkbox remains selected
          visit event_path(event)
          expect(find('.task-completed-checkbox', visible: :false)['checked']).to be_truthy
        end
      end

      scenario 'the entered data should be saved automatically when submitting the event recap' do
        kpi = create(:kpi, name: 'Test Field', kpi_type: 'number', capture_mechanism: 'integer')

        campaign.add_kpi kpi

        event = create(:event,
                       start_date: Date.yesterday.to_s(:slashes),
                       end_date: Date.yesterday.to_s(:slashes),
                       campaign: campaign)

        visit event_path(event)

        fill_in 'Test Field', with: '98765'

        click_js_link 'submit'

        expect(page).to have_content('Your post event report has been submitted for approval.')
        expect(page).to have_content('TEST FIELD 98,765')
      end

      scenario 'should not submit the event data if there are validation errors' do
        kpi = create(:kpi, name: 'Test Field', kpi_type: 'number', capture_mechanism: 'integer')

        field = campaign.add_kpi(kpi)
        field.required = 'true'
        field.save

        event = create(:event,
                       start_date: Date.yesterday.to_s(:slashes),
                       end_date: Date.yesterday.to_s(:slashes),
                       campaign: campaign)

        visit event_path(event)

        click_js_link 'submit'

        expect(find_field('Test Field')).to have_error('This field is required.')

        expect(page).to have_no_content('Your post event report has been submitted for approval.')
      end

      scenario 'allows to unapprove an approved event' do
        event = create(:approved_event,
                       start_date: Date.yesterday.to_s(:slashes),
                       end_date: Date.yesterday.to_s(:slashes),
                       campaign: campaign)

        visit event_path(event)

        expect(page).to have_content('Your post event report has been approved. Click here to unapprove.')

        click_js_link 'unapprove'

        expect(page).to have_content('Your post event report has been submitted for approval.')
      end

      scenario "display errors when an event don't meet a campaign module range" do
        event = create(:late_event,
                       campaign: create(:campaign, company: company, name: 'Campaign FY2012', brands: [brand], modules: { 'comments' => { 'name' => 'comments', 'field_type' => 'module', 'settings' => { 'range_min' => '1', 'range_max' => '2'} } }))

        visit event_path(event)

        expect(page).to have_content('Your post event report is late. Please submit post event data and enter comments now. Once complete, please submit your post event form.')

        click_js_link 'submit'

        within visible_modal do
          expect(page).to have_content('It is required at least 1 and not more than 2 comments')
          click_js_link 'OK'
        end
        ensure_modal_was_closed

        event.comments << create(:comment, content: 'Comment #1', commentable: event)
        event.save

        click_js_link 'submit'

        expect(page).to have_content('Your post event report has been submitted for approval.')
      end
    end
  end

  def event_list_item(event)
    ".resource-item#event_#{event.id}"
  end

  def events_list
    '#events-list'
  end
end
