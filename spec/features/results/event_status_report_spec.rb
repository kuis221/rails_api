require 'rails_helper'

feature 'Results Event Status Page', js: true, search: true  do

  before do
    @company = user.companies.first
    sign_in user
  end

  feature 'as a non admin user', search: false do
    let(:company) { create(:company) }
    let(:user) { create(:user, first_name: 'Juanito', last_name: 'Bazooka', company: company, role_id: create(:non_admin_role, company: company).id) }
    let(:company_user) { user.company_users.first }
    let(:campaign) { create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company) }
    let(:area) { create(:area, name: 'Area 1', company: company) }
    let(:place) { create(:place, name: 'Place 1') }

    before { Kpi.create_global_kpis }
    before { company_user.role.permissions.create(action: :event_status, subject_class: 'Campaign') }

    scenario 'a user can play and dismiss the video tutorial' do
      visit results_event_status_path

      feature_name = 'GETTING STARTED: EVENT STATUS REPORT'

      expect(page).to have_content(feature_name)
      expect(page).to have_content('This section allows you to quickly track your Event Status.')
      click_link 'Play Video'

      within visible_modal do
        click_js_link 'Close'
      end
      ensure_modal_was_closed

      within('.new-feature') do
        click_js_link 'Dismiss'
      end
      wait_for_ajax

      visit results_gva_path
      expect(page).to have_no_content(feature_name)
    end

    scenario 'should display the event status report for selected campaign and grouping' do
      area.places << place
      campaign.areas << area
      company_user.campaigns << campaign
      company_user.areas << area

      create(:goal, goalable: campaign, kpi: Kpi.promo_hours, value: '77')
      create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.promo_hours, value: 100)
      create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.events, value: 10)
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.events, value: 3)
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.promo_hours, value: 14)

      create(:approved_event, company: company, campaign: campaign, place: place,
            user_ids: [company_user.id],
            start_time: '08:00AM', end_time: '9:00AM', start_date: '01/23/2013', end_date: '01/23/2013')
      create(:submitted_event, company: company, campaign: campaign, place: place,
            user_ids: [company_user.id],
            start_time: '08:00AM', end_time: '10:00AM', start_date: '01/23/2013', end_date: '01/23/2013')
      create(:rejected_event, company: company, campaign: campaign, place: place,
            user_ids: [company_user.id],
            start_time: '08:00AM', end_time: '10:00AM', start_date: '01/23/2020', end_date: '01/23/2020')
      create(:event, company: company, campaign: campaign, place: place,
            user_ids: [company_user.id],
            start_time: '08:00AM', end_time: '10:00AM', start_date: '01/23/2020', end_date: '01/23/2020')

      visit results_event_status_path

      choose_campaign('Test Campaign FY01')

      within('.container-kpi-trend') do
        expect(page).to have_selector('.executed-label', text: '3')
        expect(page).to have_selector('.scheduled-label', text: '4')
        expect(page).to have_content('77 GOAL')
        within('.remaining-label') do
          expect(page).to have_content('70 PROMO HOURS REMAINING')
        end
      end

      # Testing group by Place
      report_form.find('label', text: 'Place').click

      within('.container-kpi-trend .kpi-trend:nth-child(1)') do
        expect(page).to have_selector('.executed-label', text: '2')
        expect(page).to have_selector('.scheduled-label', text: '2')
        expect(page).to have_content('3 GOAL')
        within('.remaining-label') do
          expect(page).to have_content('1 EVENTS OVER')
        end
      end

      within('.container-kpi-trend .kpi-trend:nth-child(2)') do
        expect(page).to have_selector('.executed-label', text: '3')
        expect(page).to have_selector('.scheduled-label', text: '4')
        expect(page).to have_content('14 GOAL')
        within('.remaining-label') do
          expect(page).to have_content('7 PROMO HOURS REMAINING')
        end
      end

      # Testing group by Staff
      report_form.find('label', text: 'Staff').click

      within('.container-kpi-trend .kpi-trend:nth-child(1)') do
        expect(page).to have_selector('.executed-label', text: '2')
        expect(page).to have_selector('.scheduled-label', text: '2')
        expect(page).to have_content('10 GOAL')
        within('.remaining-label') do
          expect(page).to have_content('6 EVENTS REMAINING')
        end
      end

      within('.container-kpi-trend .kpi-trend:nth-child(2)') do
        expect(page).to have_selector('.executed-label', text: '3')
        expect(page).to have_selector('.scheduled-label', text: '4')
        expect(page).to have_content('100 GOAL')
        within('.remaining-label') do
          expect(page).to have_content('93 PROMO HOURS REMAINING')
        end
      end
    end

    scenario 'should export the overall campaign Event Status to Excel' do
      campaign.places << place
      company_user.campaigns << campaign
      company_user.places << place

      create(:goal, goalable: campaign, kpi: Kpi.promo_hours, value: 100)
      create(:goal, goalable: campaign, kpi: Kpi.events, value: 2)

      create(:approved_event, company: company, campaign: campaign, place: place)
      create(:submitted_event, company: company, campaign: campaign, place: place)

      visit results_event_status_path

      choose_campaign('Test Campaign FY01')

      # Export
      export_report

      expect(ListExport.last).to have_rows([
        ['METRIC', 'GOAL', 'EXECUTED', 'EXECUTED %', 'SCHEDULED', 'SCHEDULED %', 'REMAINING', 'REMAINING %'],
        ['PROMO HOURS', '100', '2', '0.02', '2', '0.02', '96', '0.96'],
        ['EVENTS', '2', '1', '0.5', '1', '0.5', '0', '0']
      ])
    end

    scenario 'should export the Event Status grouped by Place to Excel' do
      area.places << place
      campaign.areas << area
      company_user.campaigns << campaign
      company_user.areas << area

      create(:goal, parent: campaign, goalable: area, kpi: Kpi.promo_hours, value: 10)
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.events, value: 2)

      create(:approved_event, company: company, campaign: campaign, place: place)
      create(:submitted_event, company: company, campaign: campaign, place: place)

      visit results_event_status_path

      choose_campaign('Test Campaign FY01')

      report_form.find('label', text: 'Place').click

      # Export
      export_report

      expect(ListExport.last).to have_rows([
        ['PLACE/AREA', 'METRIC', 'GOAL', 'EXECUTED', 'EXECUTED %', 'SCHEDULED', 'SCHEDULED %', 'REMAINING', 'REMAINING %'],
        ['Area 1', 'EVENTS', '2', '1', '0.5', '1', '0.5', '0', '0'],
        ['Area 1', 'PROMO HOURS', '10', '2', '0.2', '2', '0.2', '6', '0.6']
      ])
    end

    scenario 'should export the Event Status grouped by Staff to Excel' do
      area.places << place
      campaign.areas << area
      company_user.campaigns << campaign
      company_user.areas << area

      create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.promo_hours, value: 10)
      create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.events, value: 2)

      create(:approved_event, company: company, campaign: campaign, place: place, user_ids: [company_user.id])
      create(:submitted_event, company: company, campaign: campaign, place: place, user_ids: [company_user.id])

      visit results_event_status_path

      choose_campaign('Test Campaign FY01')

      report_form.find('label', text: 'Staff').click

      # Export
      export_report

      expect(ListExport.last).to have_rows([
        ['USER/TEAM', 'METRIC', 'GOAL', 'EXECUTED', 'EXECUTED %', 'SCHEDULED', 'SCHEDULED %', 'REMAINING', 'REMAINING %'],
        ['Juanito Bazooka', 'EVENTS', '2', '1', '0.5', '1', '0.5', '0', '0'],
        ['Juanito Bazooka', 'PROMO HOURS', '10', '2', '0.2', '2', '0.2', '6', '0.6']
      ])
    end

    scenario 'should be able to export the overall campaign Event Status as PDF' do
      campaign.places << place
      company_user.campaigns << campaign
      company_user.places << place

      create(:goal, goalable: campaign, kpi: Kpi.promo_hours, value: 100)
      create(:goal, goalable: campaign, kpi: Kpi.events, value: 2)

      create(:approved_event, company: company, campaign: campaign, place: place)
      create(:submitted_event, company: company, campaign: campaign, place: place)

      visit results_event_status_path

      choose_campaign('Test Campaign FY01')

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
        expect(text).to include 'TestCampaignFY01'
        expect(text).to include '100GOAL'
        expect(text).to include '96PROMOHOURSREMAINING22'
        expect(text).to include '2GOAL'
        expect(text).to include '0REMAINING'
      end
    end

    scenario 'should be able to export the campaign Event Status grouped by Place as PDF' do
      area.places << place
      campaign.areas << area
      company_user.campaigns << campaign
      company_user.areas << area

      create(:goal, parent: campaign, goalable: area, kpi: Kpi.promo_hours, value: 10)
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.events, value: 2)

      create(:approved_event, company: company, campaign: campaign, place: place)
      create(:submitted_event, company: company, campaign: campaign, place: place)

      visit results_event_status_path

      choose_campaign('Test Campaign FY01')

      report_form.find('label', text: 'Place').click

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
        expect(text).to include 'TestCampaignFY01'
        expect(text).to include 'Area1'
        expect(text).to include '2GOAL'
        expect(text).to include 'EVENTS'
        expect(text).to include '0REMAINING11'
        expect(text).to include '10GOAL'
        expect(text).to include 'PROMOHOURS'
        expect(text).to include '6REMAINING22'
      end
    end

    scenario 'should be able to export the campaign Event Status grouped by Staff as PDF' do
      area.places << place
      campaign.areas << area
      company_user.campaigns << campaign
      company_user.areas << area

      create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.promo_hours, value: 10)
      create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.events, value: 2)

      create(:approved_event, company: company, campaign: campaign, place: place, user_ids: [company_user.id])
      create(:submitted_event, company: company, campaign: campaign, place: place, user_ids: [company_user.id])

      visit results_event_status_path

      choose_campaign('Test Campaign FY01')

      report_form.find('label', text: 'Staff').click

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
        expect(text).to include 'TestCampaignFY01'
        expect(text).to include 'JuanitoBazooka'
        expect(text).to include '2GOAL'
        expect(text).to include 'EVENTS'
        expect(text).to include '0REMAINING11'
        expect(text).to include '10GOAL'
        expect(text).to include 'PROMOHOURS'
        expect(text).to include '6REMAINING22'
      end
    end
  end

  def report_form
    find('form#report-settings')
  end

  def choose_campaign(name)
    select_from_chosen(name, from: 'report[campaign_id]')
  end

  def export_report(format = 'XLS')
    with_resque do
      expect do
        click_js_link('Download')
        click_js_link("Download as #{format}")
        wait_for_ajax(10)
        within visible_modal do
          expect(page).to have_content('We are processing your request, the download will start soon...')
        end
        wait_for_ajax(30)
        ensure_modal_was_closed
      end.to change(ListExport, :count).by(1)
    end
  end
end
