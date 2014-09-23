require 'rails_helper'
require 'open-uri'

require_relative '../../../app/controllers/brand_ambassadors/visits_controller'

feature "Brand Ambassadors Visits" do
  let(:company) { FactoryGirl.create(:company) }
  let(:campaign) { FactoryGirl.create(:campaign, name: 'My Campaign', company: company) }
  let(:user) { FactoryGirl.create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { FactoryGirl.create(:place, name: 'A Nice Place in the APP', country:'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }
  let(:area) { FactoryGirl.create(:area, name: 'My Area', company: company) }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
    Company.current = company
    ResqueSpec.reset!
  end

  after do
    Warden.test_reset!
  end

  shared_examples_for 'a user that can view the list of visits' do
    let(:month_number) { Time.now.strftime('%m') }
    let(:month_name) { Time.now.strftime('%b') }
    let(:year_number) { Time.now.strftime('%Y') }
    let(:today) { Time.zone.local(year_number, month_number, 18, 12, 00) }
    let(:area) { FactoryGirl.create(:area, name: 'Gran Area Metropolitana', company: company) }

    before do
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: today, end_date: (today+1.day).to_s(:slashes),
        city: 'San Jose', area: area, campaign: campaign,
        visit_type: 'market_visit', company_user: company_user, active: true)
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: (today+2.days).to_s(:slashes), end_date: (today+3.days).to_s(:slashes),
        city: 'Cartago', area: area, campaign: campaign,
        visit_type: 'market_visit', company_user: company_user, active: true)
      Sunspot.commit
    end

    scenario "a list of visits is displayed" do
      visit brand_ambassadors_root_path

      choose_predefined_date_range 'Current month'

      within("ul#visits-list") do
        # First Row
        within("li:nth-child(1)") do
          expect(page).to have_content('Market Visit')
          expect(page).to have_content('Gran Area Metropolitana (San Jose)')
          expect(page).to have_content(company_user.full_name)
          expect(page).to have_content("#{month_name} 18")
          expect(page).to have_content("#{month_name} 19")
        end
        # Second Row
        within("li:nth-child(2)") do
          expect(page).to have_content('Market Visit')
          expect(page).to have_content('Gran Area Metropolitana (Cartago)')
          expect(page).to have_content(company_user.full_name)
          expect(page).to have_content("#{month_name} 20")
          expect(page).to have_content("#{month_name} 21")
        end
      end
    end

    scenario "should be able to export as xls" do
      visit brand_ambassadors_root_path
      choose_predefined_date_range 'Current month'

      click_js_link 'Download'
      click_js_link 'Download as XLS'

      within visible_modal do
        expect(page).to have_content('We are processing your request, the download will start soon...')
        expect(ListExportWorker).to have_queued(ListExport.last.id)
        ResqueSpec.perform_all(:export)
      end
      ensure_modal_was_closed

      expect(ListExport.last).to have_rows([
        ["START DATE", "END DATE", "EMPLOYEE", "AREA", "CITY", "CAMPAIGN", "TYPE"],
        ["2014-09-18", "2014-09-19", "Test User", "Gran Area Metropolitana", "San Jose", 'My Campaign', "Market Visit"],
        ["2014-09-20", "2014-09-21", "Test User", "Gran Area Metropolitana", "Cartago", 'My Campaign', "Market Visit"]
      ])
    end

    scenario "should be able to export as PDF" do
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
      reader.pages.each do |page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = page.text.gsub(/[\s\n]/, '')
        expect(text).to include '2visits'
        expect(text).to include "MarketVisit"
        expect(text).to match /#{month_name}18/
        expect(text).to match /#{month_name}19/
        expect(text).to match /#{month_name}20/
        expect(text).to match /#{month_name}21/
      end
    end
  end

  shared_examples_for 'a user that can filter the list of visits' do
    let(:today) { Time.zone.local(Time.now.year, Time.now.month, 18, 12, 00) }
    let(:another_user){ FactoryGirl.create(:company_user, user: FactoryGirl.create(:user, first_name: 'Roberto', last_name: 'Gomez'), company: company) }
    let(:area1){ FactoryGirl.create(:area, name: 'California', company: company) }
    let(:area2){ FactoryGirl.create(:area, name: 'Texas', company: company) }
    let(:place1){ FactoryGirl.create(:place, name: 'Place 1', city: 'Los Angeles', state:'CA', country: 'US', types: ['political', 'locality']) }
    let(:place2){ FactoryGirl.create(:place, name: 'Place 2', city: 'Austin', state:'TX', country: 'US', types: ['political', 'locality']) }
    let(:campaign1){ FactoryGirl.create(:campaign, name: 'Campaign FY2012',company: company) }
    let(:campaign2){ FactoryGirl.create(:campaign, name: 'Another Campaign April 03',company: company) }
    let(:ba_visit1){ FactoryGirl.create(:brand_ambassadors_visit, company: company,
                      start_date: today, end_date: (today+1.day).to_s(:slashes),
                      city: 'Los Angeles', area: area1, campaign: campaign,
                      visit_type: 'brand_program', description: 'Visit1 description',
                      company_user: company_user, active: true) }
    let(:ba_visit2){ FactoryGirl.create(:brand_ambassadors_visit, company: company,
                      start_date: (today+1.day).to_s(:slashes), end_date: (today+4.day).to_s(:slashes),
                      city: 'Austin', area: area2, campaign: campaign,
                      visit_type: 'market_visit', description: 'Visit2 description',
                      company_user: another_user, active: true) }
    let(:event1){ FactoryGirl.create(:event, start_date: today.to_s(:slashes), company: company, active: true,
                      end_date: today.to_s(:slashes), start_time: '10:00am', end_time: '11:00am',
                      campaign: campaign1, place: place1) }
    let(:event2){ FactoryGirl.create(:event, start_date: (today+1.day).to_s(:slashes), company: company, active: true,
                      end_date: (today+2.day).to_s(:slashes), start_time: '11:00am',  end_time: '12:00pm',
                      campaign: campaign2, place: place2) }


    scenario "should allow filter visits and see the correct message" do
      Timecop.travel(today) do
        area1.places << place1
        area2.places << place2
        company_user.places << place1
        company_user.places << place2
        company_user.campaigns << campaign1
        company_user.campaigns << campaign2
        event1.users << another_user
        ba_visit1.events << event1
        ba_visit2.events << event2
        Sunspot.commit

        visit brand_ambassadors_root_path

        expect(page).to have_content('2 visits')

        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Market Visit')
        end

        expect(page).to have_filter_section(title: 'BRAND AMBASSADORS', options: ['Roberto Gomez', 'Test User'])

        filter_section('BRAND AMBASSADORS').unicheck('Test User')

        expect(page).to have_content('1 visit assigned to Test User')

        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_no_content('Market Visit')
        end

        filter_section('BRAND AMBASSADORS').unicheck('Roberto Gomez')

        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Market Visit')
        end

        expect(page).to have_content('2 visits assigned to Roberto Gomez or Test User')

        filter_section('AREAS').unicheck('California')

        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_no_content('Market Visit')
        end

        expect(page).to have_content('1 visit in California and assigned to Roberto Gomez or Test User')

        filter_section('AREAS').unicheck('Texas')

        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Market Visit')
        end

        expect(page).to have_content('2 visits in California or Texas and assigned to Roberto Gomez or Test User')

        filter_section('AREAS').unicheck('California')
        filter_section('AREAS').unicheck('Texas')
        filter_section('CITIES').unicheck('Los Angeles')

        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_no_content('Market Visit')
        end

        expect(page).to have_content('1 visit in Los Angeles and assigned to Roberto Gomez or Test User')

        filter_section('CITIES').unicheck('Austin')

        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Market Visit')
        end

        expect(page).to have_content('2 visits in Austin or Los Angeles and assigned to Roberto Gomez or Test User')

        select_filter_calendar_day("18")
        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_no_content('Market Visit')
        end

        expect(page).to have_content("1 visit taking place today in Austin or Los Angeles and assigned to Roberto Gomez or Test User")

        select_filter_calendar_day("18", "19")
        within("ul#visits-list") do
          expect(page).to have_content('Brand Program')
          expect(page).to have_content('Market Visit')
        end

        expect(page).to have_content("2 visits taking place between today and tomorrow in Austin or Los Angeles and assigned to Roberto Gomez or Test User")
      end
    end
  end

  shared_examples_for 'a user that can view the calendar of visits' do
    scenario "a calendar of visits is displayed" do
      month_number = Time.now.strftime('%m')
      year = Time.now.strftime('%Y')
      month_name = Time.now.strftime('%B')
      ba_visit1 = FactoryGirl.create(:brand_ambassadors_visit, company: company,
                    start_date: "#{month_number}/15/#{year}", end_date: "#{month_number}/16/#{year}",
                    visit_type: 'market_visit', description: 'Visit1 description',
                    company_user: company_user, active: true, campaign: campaign)
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: "#{month_number}/16/#{year}", end_date: "#{month_number}/18/#{year}",
        visit_type: 'brand_program', company_user: company_user, active: true, campaign: campaign)
      Sunspot.commit

      visit brand_ambassadors_root_path

      click_link "Calendar View"

      wait_for_ajax
      within("div#calendar-view") do
        expect(find('.fc-toolbar .fc-left h2')).to have_content("#{month_name}, #{year}")
        expect(page).to have_content 'Brand Program - My Campaign Test User - Test City'
        expect(page).to have_content 'Market Visit - My Campaign Test User - Test City'

        click_link 'Market Visit'
      end

      expect(current_path).to eql brand_ambassadors_visit_path(ba_visit1)
      expect(page).to have_selector('h2', text: "Market Visit")
      expect(page).to have_content 'Test User'
      expect(page).to have_content 'Visit1 description'
    end

    scenario "should be able to export the calendar view as PDF" do
      month_number = Time.now.strftime('%m')
      year = Time.now.strftime('%Y')
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
            start_date: "#{month_number}/15/#{year}", end_date: "#{month_number}/16/#{year}",
            visit_type: 'market_visit', company_user: company_user, active: true, campaign: campaign)
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
            start_date: "#{month_number}/16/#{year}", end_date: "#{month_number}/18/#{year}",
            visit_type: 'brand_program', company_user: company_user, active: true, campaign: campaign)
      Sunspot.commit
      visit brand_ambassadors_root_path

      click_link "Calendar View"
      expect(page).to have_content('Market Visit')
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
      reader.pages.each do |page|
        # PDF to text seems to not always return the same results
        # with white spaces, so, remove them and look for strings
        # without whitespaces
        text = page.text.gsub(/[\s\n]/, '')
        expect(text).to include '2visits'
        expect(text).to include Date.today.strftime("%B,%Y")
        expect(text).to include "MarketVisit"
        expect(text).to include "BrandProgram"
      end
    end
  end

  shared_examples_for 'a user that can create visits' do
    before { campaign.save  }
    scenario 'allows the user to create a new visit' do
      area.places << FactoryGirl.create(:city, name: 'My City')
      visit brand_ambassadors_root_path

      click_js_button 'New Visit'

      within visible_modal do
        fill_in 'Start date', with: '01/23/2014'
        fill_in 'End date', with: '01/24/2014'
        select_from_chosen company_user.name, from: 'Employee'
        select_from_chosen 'Market Visit', from: 'Visit type'
        select_from_chosen 'My Area', from: 'Area'
        select_from_chosen 'My Campaign', from: 'Campaign'
        select_from_chosen 'My City', from: 'City'
        fill_in 'Description', with: 'new visit description'
        click_js_button 'Create'
      end
      ensure_modal_was_closed

      find('h2', text: 'Market Visit') # Wait for the page to load
      expect(page).to have_selector('h2', text: 'Market Visit')
      expect(page).to have_content('new visit description')
      expect(page).to have_content(company_user.name)
      expect(page).to have_content('My Campaign')
    end
  end

  shared_examples_for 'a user that can edit visits' do
    before { campaign.save  }
    scenario 'allows the user to edit a visit' do
      area.places << FactoryGirl.create(:city, name: 'My City')
      today = Time.zone.local(Time.now.strftime('%Y'), Time.now.strftime('%m'), 18, 12, 00)
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        start_date: today, end_date: (today+1.day).to_s(:slashes), campaign: campaign,
        visit_type: 'market_visit', description: 'Visit1 description',
        company_user: company_user, active: true)
      Sunspot.commit
      visit brand_ambassadors_root_path
      choose_predefined_date_range 'Current month'

      within("ul#visits-list") do
        click_js_link('Edit')
      end

      within visible_modal do
        select_from_chosen 'Brand Program', from: 'Visit type'
        select_from_chosen 'My Area', from: 'Area'
        select_from_chosen 'My Campaign', from: 'Campaign'
        select_from_chosen 'My City', from: 'City'
        fill_in 'Description', with: 'new visit description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      within("ul#visits-list") do
        expect(page).to have_content 'Brand Program'
      end
    end
  end

  shared_examples_for 'a user that can deactivate visits' do
    scenario "can deactivate a visit and it's removed from the view" do
      today = Time.zone.local(Time.now.strftime('%Y'), Time.now.strftime('%m'), 18, 12, 00)
      FactoryGirl.create(:brand_ambassadors_visit, company: company,
        campaign: campaign,
        start_date: today, end_date: (today+1.day).to_s(:slashes),
        company_user: company_user, active: true)
      Sunspot.commit
      visit brand_ambassadors_root_path

      choose_predefined_date_range 'Current month'

      within("ul#visits-list") do
        click_js_link('Deactivate')
      end

      confirm_prompt 'Are you sure you want to deactivate this visit?'

      within("ul#visits-list") do
        expect(page).to have_no_selector('li')
      end
    end
  end

  shared_examples_for 'a user that can view visits details' do
    let(:campaign){ FactoryGirl.create(:campaign, company: company, name: 'ABSOLUT Vodka') }
    let(:ba_visit){ FactoryGirl.create(:brand_ambassadors_visit, company: company,
                      start_date: '02/01/2014', end_date: '02/02/2014',
                      visit_type: 'market_visit', description: 'Visit1 description',
                      campaign: campaign, area: area,
                      company_user: company_user, active: true) }

    scenario "should display the visit details page" do
      visit brand_ambassadors_visit_path(ba_visit)
      expect(page).to have_selector('h2', text: 'Market Visit')
      expect(page).to have_content('Visit1 description')
      expect(page).to have_content(company_user.full_name)
    end

    scenario 'allows the user to edit a visit' do
      visit brand_ambassadors_visit_path(ba_visit)

      click_js_link('Edit')

      within visible_modal do
        select_from_chosen 'Brand Program', from: 'Visit type'
        fill_in 'Description', with: 'new visit description'
        click_js_button 'Save'
      end
      ensure_modal_was_closed

      expect(page).to have_selector('h2', text: 'Brand Program')
      expect(page).to have_content 'Test User'
      expect(page).to have_content 'new visit description'
    end

    scenario "allows to create a new event" do
      today = Time.zone.local(Time.now.strftime('%Y'), Time.now.strftime('%m'), 18, 12, 00)
      expect(Place).to receive(:open).and_return(double(read: '{}')) # So we don't search in google places

      Venue.create(place_id: place.id, company: company)
      FactoryGirl.create(:company_user, company: company,
        user: FactoryGirl.create(:user, first_name: 'Other', last_name: 'User'))
      campaign.save

      ba_visit = FactoryGirl.create(:brand_ambassadors_visit,
        campaign: campaign, area: area,
        start_date: today, end_date: (today+1.day).to_s(:slashes),
        company: company, company_user: company_user)
      Sunspot.commit

      visit brand_ambassadors_visit_path(ba_visit)

      within "#visit-events" do
        click_button 'Create'
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

      click_link 'You are viewing event details. Click to close.'

      expect(current_path).to eq(brand_ambassadors_visit_path(ba_visit))
      within "#visit-events" do
        expect(page).to have_content('ABSOLUT Vodka')
      end
    end
  end

  shared_examples_for 'a user that can view visits details and deactivate visits' do
    scenario "can activate/deactivate a visit from the details view" do
      ba_visit = FactoryGirl.create(:brand_ambassadors_visit,
        company: company, campaign: campaign, company_user: company_user)

      visit brand_ambassadors_visit_path(ba_visit)

      within('.links-data') do
        click_js_link('Deactivate')
      end

      confirm_prompt "Are you sure you want to deactivate this visit?"

      within('.links-data') do
        click_js_link('Activate')
        expect(page).to have_link('Deactivate') # test the link have changed
      end
    end
  end

  feature "Non Admin User", js: true, search: true do
    let(:role) { FactoryGirl.create(:non_admin_role, company: company) }

    it_should_behave_like "a user that can view the list of visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can filter the list of visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can deactivate visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can edit visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:update, 'BrandAmbassadors::Visit']]}
      before{ company_user.areas << area }
      before{ company_user.campaigns << campaign }
    end

    it_should_behave_like "a user that can create visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:create, 'BrandAmbassadors::Visit'], [:show, 'BrandAmbassadors::Visit']]}
      before{ company_user.areas << area }
      before{ company_user.campaigns << campaign }
    end

    it_should_behave_like "a user that can view the calendar of visits" do
      let(:permissions) { [[:calendar, 'BrandAmbassadors::Visit'], [:show, 'BrandAmbassadors::Visit']]}
    end

    it_should_behave_like "a user that can view visits details" do
      let(:permissions) { [
        [:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit'],
        [:show, 'BrandAmbassadors::Visit'], [:update, 'BrandAmbassadors::Visit'],
        [:create, 'Event'], [:show, 'Event']] }
      before{ company_user.campaigns << campaign }
      before{ company_user.places << place }
      before{ campaign.places << place }
      before{ company_user.areas << area }
    end

    it_should_behave_like "a user that can view visits details and deactivate visits" do
      let(:permissions) { [[:list, 'BrandAmbassadors::Visit'], [:deactivate, 'BrandAmbassadors::Visit'], [:show, 'BrandAmbassadors::Visit']]}
    end
  end

  feature "Admin User", js: true, search: true do
    let(:role) { FactoryGirl.create(:role, company: company) }

    it_behaves_like "a user that can view the list of visits"
    it_behaves_like "a user that can filter the list of visits"
    it_behaves_like "a user that can deactivate visits"
    it_behaves_like "a user that can edit visits"
    it_behaves_like "a user that can create visits"
    it_behaves_like "a user that can view visits details"
    it_behaves_like "a user that can view visits details and deactivate visits"
  end
end
