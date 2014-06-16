require 'spec_helper'

feature "Results Goals vs Actuals Page", js: true, search: true  do

  before do
    @company = user.companies.first
    sign_in user
  end

  feature "/results/gva", js: true, search: true  do
    feature "with a non admin user", search: false do
      let(:company) { FactoryGirl.create(:company) }
      let(:user){ FactoryGirl.create(:user, first_name: 'Juanito', last_name: 'Bazooka', company: company, role_id: FactoryGirl.create(:non_admin_role, company: company).id) }
      let(:company_user) { user.company_users.first }

      before { Kpi.create_global_kpis }

      scenario "a user can play and dismiss the video tutorial" do
        company_user.role.permissions.create({action: :gva_report, subject_class: 'Campaign'}, without_protection: true)

        visit results_gva_path

        feature_name = 'GOALS VS. ACTUALS'

        expect(page).to have_content(feature_name)
        expect(page).to have_content("The Goals vs. Actual section allows you")
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

      scenario "should display the GvA stats for selected campaign and grouping" do
        company_user.role.permissions.create({action: :gva_report, subject_class: 'Campaign'}, without_protection: true)
        campaign = FactoryGirl.create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        campaign.add_kpi kpi

        place1 = FactoryGirl.create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi, value: '100')
        FactoryGirl.create(:goal, parent: campaign, goalable: company_user, kpi: kpi, value: 100)
        FactoryGirl.create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.events, value: 3)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: kpi, value: 150)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.events, value: 2)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.promo_hours, value: 4)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.expenses, value: 50)

        event1 = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = FactoryGirl.create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        event3 = FactoryGirl.create(:rejected_event, company: company, campaign: campaign, place: place1)
        event3.result_for_kpi(kpi).value = '33'
        event3.save

        visit results_gva_path

        select_from_chosen('Test Campaign FY01', from: 'Campaign')

        within('.container-kpi-trend') do
          expect(page).to have_content('Samples')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '25')
          expect(page).to have_selector('.submitted-label', text: '20')
          expect(page).to have_selector('.rejected-label', text: '33')
          expect(page).to have_content('100 GOAL')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('78%')
            expect(page).to have_content('78 OF 100 GOAL')
          end
        end

        #Testing group by Place
        within('#group-by-criterion') do
          click_js_link('Place')
        end

        within('.item-summary') do
          expect(page).to have_content('Place 1')
          within('.goals-summary') do
            expect(page).to have_content('50% EVENTS')
            expect(page).to have_content('50% PROMO HOURS')
            expect(page).to have_content('0% EXPENSES')
            expect(page).to have_content('52% SAMPLES')
          end
        end

        within('.accordion-heading') do
          click_js_link('Place 1')
        end

        within('.container-kpi-trend .kpi-trend:nth-child(3)') do
          expect(page).to have_content('Samples')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '25')
          expect(page).to have_selector('.submitted-label', text: '20')
          expect(page).to have_selector('.rejected-label', text: '33')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('52%')
            expect(page).to have_content('78 OF 150 GOAL')
          end
        end

        #Testing group by Staff
        within('#group-by-criterion') do
          click_js_link('Staff')
        end

        within('.item-summary') do
          expect(page).to have_content('Juanito Bazooka')
          within('.goals-summary') do
            expect(page).to have_content('100% EVENTS')
            expect(page).to have_content('78% SAMPLES')
          end
        end

        within('.accordion-heading') do
          click_js_link('Juanito Bazooka')
        end

        within('.container-kpi-trend .kpi-trend:nth-child(2)') do
          expect(page).to have_content('Samples')
          find('.progress').hover
          expect(page).to have_selector('.executed-label', text: '25')
          expect(page).to have_selector('.submitted-label', text: '20')
          expect(page).to have_selector('.rejected-label', text: '33')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('78%')
            expect(page).to have_content('78 OF 100 GOAL')
          end
        end
      end

      scenario "should remove items from GvA results" do
        company_user.role.permissions.create({action: :gva_report, subject_class: 'Campaign'}, without_protection: true)
        campaign = FactoryGirl.create(:campaign, name: 'Test Campaign FY01', company: company)
        kpi = FactoryGirl.create(:kpi, name: 'Interactions', company: company)
        campaign.add_kpi kpi

        place = FactoryGirl.create(:place, name: 'Place 1')
        campaign.places << place
        company_user.campaigns << campaign
        company_user.places << place

        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi)
        FactoryGirl.create(:goal, parent: campaign, goalable: place, kpi: kpi)

        event1 = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place)
        event1.save

        visit results_gva_path

        within('#group-by-criterion') do
          click_js_link('Place')
        end

        select_from_chosen('Test Campaign FY01', from: 'Campaign')

        within('#gva-results') do
          expect(page).to have_content('Place 1')
          within('.accordion-heading') do
            click_js_link('Remove Place 1')
          end
          expect(page).to_not have_content('Place 1')
        end
      end

      scenario "should export the overall campaign GvA to Excel" do
        company_user.role.permissions.create({action: :gva_report, subject_class: 'Campaign'}, without_protection: true)
        campaign = FactoryGirl.create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        kpi2 = Kpi.events
        campaign.add_kpi kpi
        campaign.add_kpi kpi2

        place1 = FactoryGirl.create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi, value: '100')
        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi2, value: '2')

        event1 = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = FactoryGirl.create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        visit results_gva_path

        select_from_chosen('Test Campaign FY01', from: 'Campaign')

        # Export
        with_resque do
          expect {
            click_js_link('Download')
            wait_for_ajax(10)
            within visible_modal do
              expect(page).to have_content('We are processing your request, the download will start soon...')
            end
            wait_for_ajax(30)
            ensure_modal_was_closed
          }.to change(ListExport, :count).by(1)
        end

        spreadsheet_from_last_export do |doc|
          rows = doc.elements.to_a('//Row')
          expect(rows.count).to eql 3
          expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %']
          expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['Events', '2', '1', '0.5', '2', '1']
          expect(rows[2].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['Samples', '100', '25', '0.25', '45', '0.45']
        end
      end

      scenario "should export the GvA grouped by Place to Excel" do
        company_user.role.permissions.create({action: :gva_report, subject_class: 'Campaign'}, without_protection: true)
        campaign = FactoryGirl.create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        kpi2 = Kpi.events
        campaign.add_kpi kpi
        campaign.add_kpi kpi2

        place1 = FactoryGirl.create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: kpi, value: 150)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: kpi2, value: 2)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.promo_hours, value: 4)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.expenses, value: 50)

        event1 = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = FactoryGirl.create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        visit results_gva_path

        select_from_chosen('Test Campaign FY01', from: 'Campaign')

        within('#group-by-criterion') do
          click_js_link('Place')
        end

        # Export
        with_resque do
          expect {
            click_js_link('Download')
            wait_for_ajax(10)
            within visible_modal do
              expect(page).to have_content('We are processing your request, the download will start soon...')
            end
            wait_for_ajax(30)
            ensure_modal_was_closed
          }.to change(ListExport, :count).by(1)
        end

        spreadsheet_from_last_export do |doc|
          rows = doc.elements.to_a('//Row')
          expect(rows.count).to eql 4
          expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['PLACE/AREA', 'METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %']
          expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['Place 1', 'Events', '2', '1', '0.5', '2', '1']
          expect(rows[2].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['Place 1', 'Promo Hours', '4', '2', '0.5', '4', '1']
          expect(rows[3].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['Place 1', 'Samples', '150', '25', '0.17', '45', '0.3']
        end
      end

      scenario "should export the GvA grouped by Staff to Excel" do
        company_user.role.permissions.create({action: :gva_report, subject_class: 'Campaign'}, without_protection: true)
        campaign = FactoryGirl.create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        kpi2 = Kpi.events
        campaign.add_kpi kpi
        campaign.add_kpi kpi2

        place1 = FactoryGirl.create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        FactoryGirl.create(:goal, parent: campaign, goalable: company_user, kpi: kpi, value: 50)
        FactoryGirl.create(:goal, parent: campaign, goalable: company_user, kpi: kpi2, value: 1)

        event1 = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = FactoryGirl.create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        visit results_gva_path

        select_from_chosen('Test Campaign FY01', from: 'Campaign')

        within('#group-by-criterion') do
          click_js_link('Staff')
        end

        # Export
        with_resque do
          expect {
            click_js_link('Download')
            wait_for_ajax(10)
            within visible_modal do
              expect(page).to have_content('We are processing your request, the download will start soon...')
            end
            wait_for_ajax(30)
            ensure_modal_was_closed
          }.to change(ListExport, :count).by(1)
        end

        spreadsheet_from_last_export do |doc|
          rows = doc.elements.to_a('//Row')
          expect(rows.count).to eql 3
          expect(rows[0].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['USER/TEAM', 'METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %']
          expect(rows[1].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['Juanito Bazooka', 'Events', '1', '1', '1', '2', '2']
          expect(rows[2].elements.to_a('Cell/Data').map{|d| d.text }).to eql ['Juanito Bazooka', 'Samples', '50', '25', '0.5', '45', '0.9']
        end
      end
    end
  end
end