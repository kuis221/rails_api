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

      scenario "should display the GvA stats for selected campaign and grouping" do
        company_user.role.permissions.create({action: :gva_report, subject_class: 'Campaign'}, without_protection: true)
        campaign = FactoryGirl.create(:campaign, name: 'Test Campaign FY01', company: company)
        kpi = Kpi.interactions
        campaign.add_kpi kpi

        place1 = FactoryGirl.create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        FactoryGirl.create(:goal, goalable: campaign, kpi: kpi, value: '100')
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: kpi, value: 150)
        FactoryGirl.create(:goal, parent: campaign, goalable: company_user, kpi: kpi, value: 50)
        FactoryGirl.create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.events, value: 1)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.events, value: 2)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.promo_hours, value: 4)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.samples, value: 100)
        FactoryGirl.create(:goal, parent: campaign, goalable: place1, kpi: Kpi.expenses, value: 50)

        event1 = FactoryGirl.create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = FactoryGirl.create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        visit results_gva_path

        select_from_chosen('Test Campaign FY01', from: 'Campaign')

        within('.container-kpi-trend') do
          expect(page).to have_content('Interactions')
          expect(page).to have_content('25')
          expect(page).to have_content('45')
          expect(page).to have_content('100 GOAL')
          within('.remaining-label') do
            expect(page).to have_content('25% COMPLETE')
            expect(page).to have_content('45% PENDING')
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
            expect(page).to have_content('0% SAMPLES')
          end
        end

        within('.accordion-heading') do
          click_js_link('Place 1')
        end

        within('.container-kpi-trend .kpi-trend:nth-child(2)') do
          expect(page).to have_content('Interactions')
          expect(page).to have_content('25')
          expect(page).to have_content('45')
          expect(page).to have_content('150 GOAL')
          within('.remaining-label') do
            expect(page).to have_content('17% COMPLETE')
            expect(page).to have_content('30% PENDING')
          end
        end

        #Testing group by Staff
        within('#group-by-criterion') do
          click_js_link('Staff')
        end

        within('.item-summary') do
          expect(page).to have_content('Juanito Bazooka')
          within('.goals-summary') do
            expect(page).to have_content('51% PROMO HOURS')
            expect(page).to have_content('21% EXPENSES')
            expect(page).to have_content('83% SAMPLES')
          end
        end

        within('.accordion-heading') do
          click_js_link('Juanito Bazooka')
        end

        within('.container-kpi-trend .kpi-trend:nth-child(2)') do
          expect(page).to have_content('Interactions')
          expect(page).to have_content('25')
          expect(page).to have_content('45')
          expect(page).to have_content('50 GOAL')
          within('.remaining-label') do
            expect(page).to have_content('50% COMPLETE')
            expect(page).to have_content('90% PENDING')
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
    end
  end
end