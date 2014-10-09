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

    before { Kpi.create_global_kpis }
    before { company_user.role.permissions.create(action: :event_status, subject_class: 'Campaign') }

    scenario 'a user can play and dismiss the video tutorial' do
      visit results_event_status_path

      feature_name = 'Getting Started: Event Status Report'

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
      campaign = create(:campaign, name: 'Test Campaign FY01', company: company)
      kpi = Kpi.events

      area = create(:area, name: 'Area 1', company: company)
      place = create(:place, name: 'Place 1')
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
  end

  def report_form
    find('form#report-settings')
  end

  def choose_campaign(name)
    select_from_chosen(name, from: 'report[campaign_id]')
  end
end
