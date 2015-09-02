require 'rails_helper'
require 'open-uri'

require_relative '../../../app/controllers/brand_ambassadors/visits_controller'

feature 'Brand Ambassadors Visits' do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, name: 'My Campaign', company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place in the APP', city: 'New York', state: 'NY') }
  let(:permissions) { [] }
  let(:area) { create(:area, name: 'My Area', company: company) }
  before { area.places << create(:city, name: 'New York', state: 'NY') }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
    Company.current = company
  end

  after do
    Warden.test_reset!
  end

  shared_examples_for 'a user that can view the list of visits' do
    let(:month_number) { Time.now.strftime('%m') }
    let(:month_name) { Time.now.strftime('%b') }
    let(:year_number) { Time.now.strftime('%Y') }
    let(:today) { Time.zone.local(year_number, month_number, 18, 12, 00) }

    before do
      create(:brand_ambassadors_visit, company: company,
                                       start_date: today, end_date: (today + 1.day).to_s(:slashes),
                                       city: 'New York', area: area, campaign: campaign,
                                       visit_type: 'Formal Market Visit', company_user: company_user,
                                       description: 'The first visit description', active: true)
      create(:brand_ambassadors_visit, company: company,
                                       start_date: (today + 2.days).to_s(:slashes),
                                       end_date: (today + 3.days).to_s(:slashes),
                                       city: 'New York', area: area, campaign: campaign,
                                       visit_type: 'Brand Program', company_user: company_user, active: true)
      create(:brand_ambassadors_visit, company: company,
                                       start_date: (today + 4.days).to_s(:slashes),
                                       end_date: (today + 5.days).to_s(:slashes),
                                       city: nil, area: nil, campaign: campaign,
                                       visit_type: 'PTO', company_user: company_user, active: true)
      Sunspot.commit
    end

    scenario 'a list of visits is displayed' do
      visit brand_ambassadors_root_path

      choose_predefined_date_range 'Current month'

      # First Row
      within resource_item 1 do
        expect(page).to have_content('Formal Market Visit')
        expect(page).to have_content('My Area (New York)')
        expect(page).to have_content(company_user.full_name)
        expect(page).to have_content("#{month_name} 18")
        expect(page).to have_content("#{month_name} 19")
      end
      # Second Row
      within resource_item 2 do
        expect(page).to have_content('Brand Program')
        expect(page).to have_content('My Area (New York)')
        expect(page).to have_content(company_user.full_name)
        expect(page).to have_content("#{month_name} 20")
        expect(page).to have_content("#{month_name} 21")
      end
      # Third Row
      within resource_item 3 do
        expect(page).to have_content('PTO')
        expect(page).to have_content(company_user.full_name)
        expect(page).to have_content("#{month_name} 22")
        expect(page).to have_content("#{month_name} 23")
      end
    end

    scenario 'should be able to export as CSV' do
      visit brand_ambassadors_root_path
      choose_predefined_date_range 'Current month'

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ['START DATE', 'END DATE', 'EMPLOYEE', 'AREA', 'CITY', 'CAMPAIGN', 'TYPE', 'DESCRIPTION'],
        ["#{month_number}/18/#{year_number}", "#{month_number}/19/#{year_number}",
         'Test User', 'My Area', 'New York', 'My Campaign', 'Formal Market Visit',
         'The first visit description'],
        ["#{month_number}/20/#{year_number}", "#{month_number}/21/#{year_number}",
         'Test User', 'My Area', 'New York', 'My Campaign', 'Brand Program', 'Visit description'],
        ["#{month_number}/22/#{year_number}", "#{month_number}/23/#{year_number}",
         'Test User', nil, nil, 'My Campaign', 'PTO', 'Visit description']
      ])
    end

    scenario 'should be able to export as PDF' do
      visit brand_ambassadors_root_path

      choose_predefined_date_range 'Current month'

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
      reader.pages.each do |pdf_page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = pdf_page.text.gsub(/[\s\n]/, '')
        expect(text).to include '3visits'
        expect(text).to include 'MarketVisit'
        expect(text).to include 'BrandProgram'
        expect(text).to include 'PTO'
        expect(text).to match(/#{month_name}18/)
        expect(text).to match(/#{month_name}19/)
        expect(text).to match(/#{month_name}20/)
        expect(text).to match(/#{month_name}21/)
        expect(text).to match(/#{month_name}22/)
        expect(text).to match(/#{month_name}23/)
      end
    end

    scenario 'should not be able to export as PDF for documents with more than 200 pages' do
      allow(BrandAmbassadors::Visit).to receive(:do_search).and_return(double(total: 3000))

      visit brand_ambassadors_root_path

      click_js_link 'Download'
      click_js_link 'Download as PDF'

      within visible_modal do
        expect(page).to have_content('PDF exports are limited to 200 pages. Please narrow your results and try exporting again.')
        click_js_link 'OK'
      end
      ensure_modal_was_closed
    end
  end

  shared_examples_for 'a user that can filter the list of visits' do
    let(:today) { Time.zone.local(2015, 7, 18, 12, 00) }
    let(:another_user) { create(:company_user, user: create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company) }
    let(:area1) { create(:area, name: 'California', company: company) }
    let(:area2) { create(:area, name: 'Texas', company: company) }
    let(:place1) { create(:place, name: 'Place 1', city: 'Los Angeles', state: 'California', country: 'US') }
    let(:place2) { create(:place, name: 'Place 2', city: 'Austin', state: 'Texas', country: 'US') }
    let(:campaign1) { create(:campaign, name: 'Campaign FY2012', company: company) }
    let(:campaign2) { create(:campaign, name: 'Another Campaign April 03', company: company) }
    let(:ba_visit1) do
      create(:brand_ambassadors_visit,
             company: company,
             start_date: today, end_date: (today + 1.day).to_s(:slashes),
             city: 'Los Angeles', area: area1, campaign: campaign,
             visit_type: 'Brand Program', description: 'Visit1 description',
             company_user: company_user, active: true)
    end
    let(:ba_visit2) do
      create(:brand_ambassadors_visit,
             company: company, city: 'Austin', area: area2, campaign: campaign,
             start_date: (today + 1.day).to_s(:slashes), end_date: (today + 4.day).to_s(:slashes),
             visit_type: 'Formal Market Visit', description: 'Visit2 description',
             company_user: another_user, active: true)
    end
    let(:event1) do
      create(:event, start_date: today.to_s(:slashes), company: company, active: true,
                     end_date: today.to_s(:slashes), start_time: '10:00am', end_time: '11:00am',
                     campaign: campaign1, place: place1)
    end
    let(:event2) do
      create(:event, start_date: (today + 1.day).to_s(:slashes), company: company, active: true,
                     end_date: (today + 2.day).to_s(:slashes), start_time: '11:00am',
                     end_time: '12:00pm', campaign: campaign2, place: place2)
    end

    scenario 'should allow filter visits and see the correct message' do
      Timecop.travel(today) do
        la = create(:city, name: 'Los Angeles', state: 'California', country: 'US')
        au = create(:city, name: 'Austin', state: 'Texas', country: 'US')
        area1.places << [la, au]
        area2.places << [la, au]
        Sunspot.index [area1, area2]
        company_user.areas << [area1, area2]
        company_user.places << [place1, place2]
        company_user.campaigns << [campaign1, campaign2]
        event1.users << another_user
        ba_visit1
        ba_visit2

        Sunspot.commit

        visit brand_ambassadors_root_path

        expect(page).to have_content('2 visits')

        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Formal Market Visit')
        end

        add_filter 'CAMPAIGNS', 'My Campaign'

        expect(page).to have_content('2 visits found for: Today To The Future My Campaign')

        within '#visits-list' do
          expect(page).to have_content('My Campaign')
          expect(page).to have_no_content('Campaign FY2012')
          expect(page).to have_no_content('Another Campaign April 03')
        end

        expect(page).to have_filter_section(title: 'BRAND AMBASSADORS', options: ['Roberto Gomez', 'Test User'])

        remove_filter 'My Campaign'
        add_filter 'BRAND AMBASSADORS', 'Test User'

        expect(page).to have_content('1 visit found for: Today To The Future Test User')

        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_no_content('Formal Market Visit')
        end

        add_filter 'BRAND AMBASSADORS', 'Roberto Gomez'

        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Formal Market Visit')
        end

        expect(page).to have_content('2 visits found for: Today To The Future Roberto Gomez Test User')

        add_filter 'AREAS', 'California'

        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_no_content('Formal Market Visit')
        end

        expect(page).to have_content('1 visit found for: Today To The Future California Roberto Gomez Test User')

        add_filter 'AREAS', 'Texas'

        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Formal Market Visit')
        end

        expect(page).to have_content('2 visits found for: Today To The Future California Texas Roberto Gomez Test User')

        remove_filter 'California'
        remove_filter 'Texas'
        add_filter 'CITIES', 'Los Angeles'

        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_no_content('Formal Market Visit')
        end

        expect(page).to have_content('1 visit found for: Today To The Future Los Angeles Roberto Gomez Test User')

        filter_section('CITIES').unicheck('Austin')

        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Formal Market Visit')
        end

        expect(page).to have_content('2 visits found for: Today To The Future Austin Los Angeles Roberto Gomez Test User')

        select_filter_calendar_day('18')
        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_no_content('Formal Market Visit')
        end

        expect(page).to have_content('1 visit found for: Today Austin Los Angeles Roberto Gomez Test User')

        select_filter_calendar_day('18', '19')
        within '#visits-list' do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Formal Market Visit')
        end

        expect(page).to have_content('2 visits found for: Today - Tomorrow Austin Los Angeles Roberto Gomez Test User')
      end
    end
  end

  shared_examples_for 'a user that can view the calendar of visits' do
    scenario 'a calendar of visits is displayed' do
      month_number = Time.now.strftime('%m')
      year = Time.now.strftime('%Y')
      month_name = Time.now.strftime('%B')
      ba_visit1 = create(:brand_ambassadors_visit, company: company,
                    start_date: "#{month_number}/15/#{year}", end_date: "#{month_number}/15/#{year}",
                    visit_type: 'Formal Market Visit', description: 'Visit1 description',
                    city: 'New York', area: area,
                    company_user: company_user, active: true, campaign: campaign)
      create(:brand_ambassadors_visit, company: company,
        start_date: "#{month_number}/16/#{year}", end_date: "#{month_number}/18/#{year}",
        city: 'New York', area: area,
        visit_type: 'Brand Program', company_user: company_user, active: true, campaign: campaign)
      Sunspot.commit

      visit brand_ambassadors_root_path

      click_link 'Calendar View'

      wait_for_ajax
      within('div#calendar-view') do
        expect(find('.fc-toolbar .fc-left h2')).to have_content("#{month_name}, #{year}")
        expect(page).to have_content 'Brand Program - My Campaign Test User - New York'
        expect(page).to have_content 'Formal Market Visit - My Campaign Test User - New York'

        click_link 'Formal Market Visit'
      end

      expect(current_path).to eql brand_ambassadors_visit_path(ba_visit1)
      expect(page).to have_selector('h2', text: 'Formal Market Visit')
      expect(page).to have_content 'Test User'
      expect(page).to have_content 'Visit1 description'

      # Ensure that the "close" link is going to the calendar view
      click_link 'You are viewing visit details. Click to close.'

      expect(page).to have_css('div#calendar-view.tab-pane.active')
      expect(page).to have_no_css('div#visits-scoller-outer.tab-pane.active')
    end

    scenario 'should be able to export the calendar view as PDF' do
      month_number = Time.now.strftime('%m')
      year = Time.now.strftime('%Y')
      create(:brand_ambassadors_visit,
             company: company, city: 'New York', area: area, campaign: campaign,
             start_date: "#{month_number}/15/#{year}", end_date: "#{month_number}/16/#{year}",
             visit_type: 'Formal Market Visit', company_user: company_user, active: true)
      create(:brand_ambassadors_visit,
             company: company, city: 'New York', area: area, campaign: campaign,
             start_date: "#{month_number}/16/#{year}", end_date: "#{month_number}/18/#{year}",
             visit_type: 'Brand Program', company_user: company_user, active: true)
      Sunspot.commit
      visit brand_ambassadors_root_path

      click_link 'Calendar View'
      expect(page).to have_content('Formal Market Visit')
      expect(page).to have_content('Brand Program')

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
      expect(export.params).to include(mode: 'calendar')

      # Test the generated PDF...
      require 'open-uri'
      reader = PDF::Reader.new(open(export.file.url))
      reader.pages.each do |pdf_page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = pdf_page.text.gsub(/[\s\n]/, '')
        expect(text).to include '2visits'
        expect(text).to include Date.today.strftime('%B,%Y')
        expect(text).to include 'MarketVisit'
        expect(text).to include 'BrandProgram'
      end
    end
  end

  shared_examples_for 'a user that can create visits' do
    before { campaign.save  }

    scenario 'allows the user to create a new visit' do
      area.places << create(:city, name: 'My City')
      visit brand_ambassadors_root_path

      click_js_button 'New Visit'

      within visible_modal do
        fill_in 'Start date', with: '01/23/2014'
        fill_in 'End date', with: '01/24/2014'
        select_from_chosen company_user.name, from: 'Employee'
        select2_add_tag 'Visit type', from: 'Formal Market Visit'
        select_from_chosen 'My Area', from: 'Area'
        select_from_chosen 'My Campaign', from: 'Campaign'
        select_from_chosen 'My City', from: 'City'
        fill_in 'Description', with: 'new visit description'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'Formal Market Visit') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'Formal Market Visit')
      expect(page).to have_content('new visit description')
      expect(page).to have_content(company_user.name)
      expect(page).to have_content('My Campaign')
    end
  end

  shared_examples_for 'a user that can edit visits' do
    let(:ba_visit) do
      create(:brand_ambassadors_visit,
             company: company, campaign: campaign,
             visit_type: 'Formal Market Visit', description: 'Visit1 description',
             area: area, city: 'New York', company_user: company_user, active: true)
    end
    before do
      ba_visit.save
      Sunspot.commit
    end
    scenario 'allows the user to edit a visit' do
      area.places << create(:city, name: 'My City')
      visit brand_ambassadors_root_path
      choose_predefined_date_range 'Current month'

      within resource_item do
        click_js_button 'Edit Visit'
      end

      within visible_modal do
        expect(find('#s2id_brand_ambassadors_visit_visit_type')).to have_content 'Formal Market Visit'
        expect(find_field('Area', visible: false).value).to eql area.id.to_s
        expect(find_field('Campaign', visible: false).value).to eql campaign.id.to_s
        expect(find_field('City', visible: false).value).to eql 'New York'
        expect(find_field('Description', visible: false).value).to eql 'Visit1 description'
        select2_remove_tag 'Formal Market Visit'
        select2_add_tag 'Visit type', 'Brand Program'
        select_from_chosen 'My Area', from: 'Area'
        select_from_chosen 'My Campaign', from: 'Campaign'
        select_from_chosen 'My City', from: 'City'
        fill_in 'Description', with: 'new visit description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within resource_item do
        expect(page).to have_content company_user.full_name
        expect(page).to have_content 'My Area (My City)'
        expect(page).to have_content campaign.name
        expect(page).to have_content 'Brand Program'
      end
    end

    scenario 'user is redirected to the list of visits after editing' do
      visit brand_ambassadors_root_path

      within resource_item do
        click_link 'Visit Details'
      end
      expect(current_path).to eql brand_ambassadors_visit_path(ba_visit)

      within('.edition-links') { click_js_button 'Edit Visit' }
      within visible_modal do
        fill_in 'Description', with: 'Some description'
        click_js_button 'Save'
      end

      expect(page).to have_text('Some description')

      click_link 'You are viewing visit details. Click to close.'
      expect(current_path).to eql brand_ambassadors_root_path
    end
  end

  shared_examples_for 'a user that can edit visits without permission to add tab' do
    let(:ba_visit) do
      create(:brand_ambassadors_visit,
             company: company, campaign: campaign,
             visit_type: 'Formal Market Visit', description: 'Visit1 description',
             area: area, city: 'New York', company_user: company_user, active: true)
    end
    let(:ba_visit2) do
      create(:brand_ambassadors_visit,
             company: company, campaign: campaign,
             visit_type: 'Brand Program', description: 'Visit2 description',
             area: area, city: 'Florida', company_user: company_user, active: true)
    end
    before do
      ba_visit.save
      ba_visit2.save
      Sunspot.commit
    end
    scenario 'allows the user to edit a visit' do
      area.places << create(:city, name: 'My City')
      visit brand_ambassadors_root_path
      choose_predefined_date_range 'Current month'

      within resource_item do
        click_js_button 'Edit Visit'
      end

      within visible_modal do
        expect(find_field('Visit type', visible: false).value).to eql 'Formal Market Visit'
        expect(find_field('Area', visible: false).value).to eql area.id.to_s
        expect(find_field('Campaign', visible: false).value).to eql campaign.id.to_s
        expect(find_field('City', visible: false).value).to eql 'New York'
        expect(find_field('Description', visible: false).value).to eql 'Visit1 description'
        select_from_chosen 'Brand Program', from: 'Visit type'
        select_from_chosen 'My Area', from: 'Area'
        select_from_chosen 'My Campaign', from: 'Campaign'
        select_from_chosen 'My City', from: 'City'
        fill_in 'Description', with: 'new visit description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within resource_item do
        expect(page).to have_content company_user.full_name
        expect(page).to have_content 'My Area (My City)'
        expect(page).to have_content campaign.name
        expect(page).to have_content 'Brand Program'
      end
    end

    scenario 'user is redirected to the list of visits after editing' do
      visit brand_ambassadors_root_path

      within resource_item do
        click_link 'Visit Details'
      end
      expect(current_path).to eql brand_ambassadors_visit_path(ba_visit)

      within('.edition-links') { click_js_button 'Edit Visit' }
      within visible_modal do
        fill_in 'Description', with: 'Some description'
        click_js_button 'Save'
      end

      expect(page).to have_text('Some description')

      click_link 'You are viewing visit details. Click to close.'
      expect(current_path).to eql brand_ambassadors_root_path
    end
  end

  shared_examples_for 'a user that can deactivate visits' do
    scenario "can deactivate a visit and it's removed from the view" do
      today = Time.zone.local(Time.now.strftime('%Y'), Time.now.strftime('%m'), 18, 12, 00)
      create(:brand_ambassadors_visit,
             company: company, campaign: campaign, area: area, city: 'New York',
             start_date: today, end_date: (today + 1.day).to_s(:slashes),
             company_user: company_user, active: true)
      Sunspot.commit
      visit brand_ambassadors_root_path

      choose_predefined_date_range 'Current month'

      within resource_item do
        click_js_button 'Deactivate Visit'
      end

      confirm_prompt 'Are you sure you want to deactivate this visit?'

      within '#visits-list' do
        expect(page).to have_no_selector('.resource-item')
      end
    end
  end

  shared_examples_for 'a user that can view visits details' do
    let(:campaign) { create(:campaign, company: company, name: 'ABSOLUT Vodka') }
    let(:ba_visit)do
      create(:brand_ambassadors_visit, company: company,
                                       start_date: '02/01/2014', end_date: '02/02/2014',
                                       visit_type: 'Formal Market Visit', description: 'Visit1 description',
                                       campaign: campaign, area: area,
                                       company_user: company_user, active: true)
    end

    scenario 'should display the visit details page' do
      visit brand_ambassadors_visit_path(ba_visit)
      expect(page).to have_selector('h2', text: 'Formal Market Visit')
      expect(page).to have_content('Visit1 description')
      expect(page).to have_content(company_user.full_name)
    end

    scenario 'allows the user to edit a visit' do
      visit brand_ambassadors_visit_path(ba_visit)

      click_js_button('Edit')

      within visible_modal do
        select2_remove_tag 'Formal Market Visit'
        select2_add_tag 'Visit type', 'Brand Program'
        fill_in 'Description', with: 'new visit description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'Brand Program')
      expect(page).to have_content 'Test User'
      expect(page).to have_content 'new visit description'
    end

    scenario 'can view a list of events in the same area and campaign, with the user in team and inside the date range' do
      cities = [
        create(:city, name: 'San Francisco', state: 'CA'),
        create(:city, name: 'New York', state: 'NY')
      ]
      company_user.places << cities
      campaign.places << cities

      without_current_user do
        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               users: [company_user],
               place: create(:place, name: 'My Place 1', city: 'New York', state: 'NY'))

        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               users: [company_user],
               place: create(:place, name: 'My Place 2', city: 'San Francisco', state: 'CA'))

        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               place: create(:place, name: 'My Place 3', city: 'New York', state: 'NY'))
      end
      Sunspot.commit

      visit brand_ambassadors_visit_path(ba_visit)

      within '#events-list' do
        expect(page).to have_content('My Place 1')
        expect(page).not_to have_content('My Place 2')
        expect(page).not_to have_content('My Place 3')
      end
    end

    scenario 'if the visit doesn\'t have an area, display all events matching the other criteria'  do
      cities = [
        create(:city, name: 'San Francisco', state: 'CA'),
        create(:city, name: 'New York', state: 'NY'),
      ]
      company_user.places << cities
      campaign.places << cities

      without_current_user do
        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               users: [company_user],
               place: create(:place, name: 'My Place 1', city: 'New York', state: 'NY'))

        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               users: [company_user],
               place: create(:place, name: 'My Place 2', city: 'San Francisco', state: 'CA'))

        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               place: create(:place, name: 'My Place 3', city: 'New York', state: 'NY'))
      end

      ba_visit1 = create(:brand_ambassadors_visit,
                        company: company,
                        start_date: '02/01/2014', end_date: '02/02/2014',
                        visit_type: 'Formal Market Visit', description: 'Visit1 description',
                        campaign: campaign, area: nil,
                        company_user: company_user, active: true)

      Sunspot.commit
      visit brand_ambassadors_visit_path(ba_visit1)

      within '#events-list' do
        expect(page).to have_content('My Place 1')
        expect(page).to have_content('My Place 2')
        expect(page).not_to have_content('My Place 3')
      end
    end

    scenario 'should be able to export as CSV' do
      cities = [
        create(:city, name: 'San Francisco', state: 'CA'),
        create(:city, name: 'New York', state: 'NY')
      ]
      company_user.places << cities
      campaign.places << cities

      event1 = create(:event, start_date: '02/01/2014', end_date: '02/01/2014',
                              start_time: '10:00am', end_time: '11:00am',
                              campaign: campaign,
                              users: [company_user],
                              place: create(:place, name: 'My Place 1', city: 'New York', state: 'NY'))

      create(:event, start_date: '02/01/2014', end_date: '02/01/2014',
                     start_time: '09:00am', end_time: '11:00am',
                     campaign: campaign,
                     place: create(:place, name: 'My Place 2', city: 'San Francisco', state: 'CA'))

      event3 = create(:event, start_date: '02/01/2014', end_date: '02/01/2014',
                              start_time: '09:00am', end_time: '11:00am',
                              campaign: campaign,
                              users: [company_user],
                              place: create(:place, name: 'My Place 3', city: 'New York', state: 'NY'))
      Sunspot.commit

      visit brand_ambassadors_visit_path(ba_visit)

      click_js_link 'Download'
      click_js_link 'Download as CSV'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed
      expect(ListExport.last).to have_rows([
        ['CAMPAIGN NAME', 'AREA', 'START', 'END', 'DURATION', 'VENUE NAME', 'ADDRESS', 'CITY',
         'STATE', 'ZIP', 'ACTIVE STATE', 'EVENT STATUS', 'TEAM MEMBERS', 'CONTACTS', 'URL'],
        ['ABSOLUT Vodka', '', "2014-02-01 09:00","2014-02-01 11:00", '2.00', 'My Place 3',
         'My Place 3, 11 Main St., New York, NY, 12345', 'New York', 'NY', '12345', 'Active', 'Unsent',
         'Test User', '', "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/events/#{event3.id}"],
        ['ABSOLUT Vodka', '', "2014-02-01 10:00","2014-02-01 11:00", '1.00', 'My Place 1',
         'My Place 1, 11 Main St., New York, NY, 12345', 'New York', 'NY', '12345', 'Active', 'Unsent',
         'Test User', '', "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/events/#{event1.id}"]
      ])
    end

    scenario 'should be able to export as PDF' do
      cities = [
        create(:city, name: 'San Francisco', state: 'CA'),
        create(:city, name: 'New York', state: 'NY')
      ]
      company_user.places << cities
      campaign.places << cities

      create(:event, start_date: '02/01/2014', end_date: '02/01/2014',
                     start_time: '10:00am', end_time: '11:00am',
                     campaign: campaign, users: [company_user],
                     place: create(:place, name: 'My Place 1', city: 'New York', state: 'NY'))

      create(:event, start_date: '02/01/2014', end_date: '02/01/2014', start_time: '09:00am',
                     end_time: '11:00am', campaign: campaign,
                     place: create(:place, name: 'My Place 2', city: 'San Francisco', state: 'CA'))

      create(:event, start_date: '02/01/2014', end_date: '02/01/2014', start_time: '09:00am',
                     end_time: '11:00am', campaign: campaign, users: [company_user],
                     place: create(:place, name: 'My Place 3', city: 'New York', state: 'NY'))
      Sunspot.commit

      visit brand_ambassadors_visit_path(ba_visit)

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
        expect(text).to include 'ABSOLUTVodka'
        expect(text).to include 'NewYork,NY,12345'
        expect(text).to include '10:00AM-11:00AM'
        expect(text).to include '9:00AM-11:00AM'
        expect(text).to include 'MyPlace3'
        expect(text).to include 'MyPlace1'
      end
    end

    scenario 'can create a new event' do
      today = Time.zone.local(Time.now.strftime('%Y'), Time.now.strftime('%m'), 18, 12, 00)
      # So we don't search in google places
      expect_any_instance_of(CombinedSearch).to receive(:open).and_return(double(read: '{}'))

      Venue.create(place_id: place.id, company: company)
      create(:company_user, company: company,
                            user: create(:user, first_name: 'Other', last_name: 'User'))
      campaign.save

      ba_visit = create(:brand_ambassadors_visit,
                        campaign: campaign, area: area,
                        start_date: today, end_date: (today + 1.day).to_s(:slashes),
                        company: company, company_user: company_user)
      Sunspot.commit

      visit brand_ambassadors_visit_path(ba_visit)

      within '#visit-events' do
        click_button 'Add Event'
      end

      within visible_modal do
        expect(page).to have_content(company_user.full_name)
        find_field('event_start_date').click
        select_and_fill_from_datepicker('event_start_date', today.to_s(:slashes))
        find_field('event_end_date').click
        select_and_fill_from_datepicker('event_end_date', today.to_s(:slashes))
        select_from_chosen('ABSOLUT Vodka', from: 'Campaign')
        select_from_chosen('Other User', from: 'Event staff')
        select_from_autocomplete 'Search for a place', place.name

        fill_in 'Description', with: 'some event description'
        click_button 'Create'
      end
      ensure_modal_was_closed
      expect(page).to have_content('ABSOLUT Vodka')
      expect(page).to have_content('some event description')

      click_link 'Close Event'

      expect(current_path).to eq(brand_ambassadors_visit_path(ba_visit))
      within '#visit-events' do
        expect(page).to have_content('ABSOLUT Vodka')
      end
    end
  end

  shared_examples_for 'a user that can view visits details without auto_match_events' do
    before {
      company.auto_match_events = false
      company.save
    }
    let(:campaign) { create(:campaign, company: company, name: 'ABSOLUT Vodka') }
    let(:ba_visit)do
      create(:brand_ambassadors_visit, company: company,
                                       start_date: '02/01/2014', end_date: '02/02/2014',
                                       visit_type: 'Formal Market Visit', description: 'Visit1 description',
                                       campaign: campaign, area: area,
                                       company_user: company_user, active: true)
    end

    scenario 'can view a list of events' do
      without_current_user do
        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               users: [company_user],
               place: create(:place, name: 'My Place 1', city: 'New York', state: 'NY'),
               visit: ba_visit)

        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               users: [company_user],
               place: create(:place, name: 'My Place 2', city: 'San Francisco', state: 'CA'))

        create(:event,
               start_date: '02/01/2014', end_date: '02/01/2014',
               campaign: campaign,
               visit: ba_visit,
               place: create(:place, name: 'My Place 3', city: 'New York', state: 'NY'))
      end
      Sunspot.commit

      visit brand_ambassadors_visit_path(ba_visit)

      within '#events-list' do
        expect(page).to have_content('My Place 1')
        expect(page).not_to have_content('My Place 2')
        expect(page).to have_content('My Place 3')
      end
    end
  end

  shared_examples_for 'a user that can view visits details and deactivate visits' do
    scenario 'can activate/deactivate a visit from the details view' do
      ba_visit = create(:brand_ambassadors_visit,
                        company: company, campaign: campaign, company_user: company_user)

      visit brand_ambassadors_visit_path(ba_visit)

      within('.edition-links') do
        click_js_button 'Deactivate Visit'
      end

      confirm_prompt 'Are you sure you want to deactivate this visit?'

      within('.edition-links') do
        click_js_button 'Activate Visit'
        expect(page).to have_button 'Deactivate Visit' # test the link have changed
      end
    end
  end

  feature 'Non Admin User', js: true, search: true do
    let(:role) { create(:non_admin_role, company: company) }
    before { company_user.campaigns << campaign }
    before { company_user.areas << area }

    it_should_behave_like 'a user that can view the list of visits' do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit']] }
    end

    it_should_behave_like 'a user that can filter the list of visits' do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit']] }
    end

    it_should_behave_like 'a user that can deactivate visits' do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit']] }
    end

    it_should_behave_like 'a user that can edit visits' do
      let(:permissions) do
        [
          [:list, 'BrandAmbassadors::Visit'],
          [:show, 'BrandAmbassadors::Visit'],
          [:update, 'BrandAmbassadors::Visit'],
          [:tag, 'BrandAmbassadors::Visit']
        ]
      end
    end

    it_should_behave_like 'a user that can edit visits without permission to add tab' do
      let(:permissions) do
        [
          [:list, 'BrandAmbassadors::Visit'],
          [:show, 'BrandAmbassadors::Visit'],
          [:update, 'BrandAmbassadors::Visit']
        ]
      end
    end

    it_should_behave_like 'a user that can create visits' do
      let(:permissions) do
        [
          [:list, 'BrandAmbassadors::Visit'],
          [:create, 'BrandAmbassadors::Visit'],
          [:show, 'BrandAmbassadors::Visit'],
          [:tag, 'BrandAmbassadors::Visit']
        ]
      end
    end

    it_should_behave_like 'a user that can view the calendar of visits' do
      let(:permissions) { [[:calendar, 'BrandAmbassadors::Visit'], [:show, 'BrandAmbassadors::Visit']] }
    end

    it_should_behave_like 'a user that can view visits details' do
      let(:permissions) do
        [
          [:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit'],
          [:show, 'BrandAmbassadors::Visit'], [:update, 'BrandAmbassadors::Visit'],
          [:create, 'Event'], [:show, 'Event'], [:view_list, 'Event'], [:tag, 'BrandAmbassadors::Visit']]
      end
      before { company_user.places << place }
      before { campaign.places << place }
      before { company_user.areas << area }
    end

    it_should_behave_like 'a user that can view visits details without auto_match_events' do
      let(:permissions) do
        [
          [:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit'],
          [:show, 'BrandAmbassadors::Visit'], [:update, 'BrandAmbassadors::Visit'],
          [:create, 'Event'], [:show, 'Event'], [:view_list, 'Event'], [:tag, 'BrandAmbassadors::Visit']]
      end
    end

    it_should_behave_like 'a user that can view visits details and deactivate visits' do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit'], [:show, 'BrandAmbassadors::Visit']] }
    end
  end

  feature 'Admin User', js: true, search: true do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can view the list of visits'
    it_behaves_like 'a user that can filter the list of visits'
    it_behaves_like 'a user that can deactivate visits'
    it_behaves_like 'a user that can edit visits'
    it_behaves_like 'a user that can create visits'
    it_behaves_like 'a user that can view visits details'
    it_behaves_like 'a user that can view visits details without auto_match_events'
    it_behaves_like 'a user that can view visits details and deactivate visits'
  end
end
