require 'rails_helper'

feature 'Results Goals vs Actuals Page', js: true, search: true  do

  before do
    @company = user.companies.first
    sign_in user
  end

  feature '/analysis/gva', js: true, search: true  do
    feature 'with a non admin user', search: false do
      let(:company) { create(:company) }
      let(:user) { create(:user, first_name: 'Juanito', last_name: 'Bazooka', company: company, role_id: create(:non_admin_role, company: company).id) }
      let(:company_user) { user.company_users.first }

      before { Kpi.create_global_kpis }

      scenario 'a user can play and dismiss the video tutorial' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')

        visit analysis_gva_path

        feature_name = 'GETTING STARTED: GOALS VS. ACTUAL'

        expect(page).to have_content(feature_name)
        expect(page).to have_content('The Goals vs. Actual section allows you')
        click_link 'Play Video'

        within visible_modal do
          click_js_link 'Close'
        end
        ensure_modal_was_closed

        within('.new-feature') do
          click_js_link 'Dismiss'
        end
        wait_for_ajax

        visit analysis_gva_path
        expect(page).to have_no_content(feature_name)
      end

      scenario 'should display the GvA stats for selected campaign and grouping' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014',
                                     company: company, modules: { 'photos' => {} })
        kpi = Kpi.samples
        kpi2 = Kpi.photos
        campaign.add_kpi kpi
        campaign.add_kpi kpi2

        place = create(:place, name: 'The Place')
        another_place = create(:place, name: 'Place 3')
        campaign.places << [place, another_place]
        company_user.campaigns << campaign
        company_user.places << [place, another_place]

        create(:goal, goalable: campaign, kpi: kpi, value: '100')
        create(:goal, goalable: campaign, kpi: kpi2, value: '10')
        create(:goal, parent: campaign, goalable: company_user, kpi: kpi, value: 100)
        create(:goal, parent: campaign, goalable: company_user, kpi: Kpi.events, value: 3)
        create(:goal, parent: campaign, goalable: place, kpi: kpi, value: 150)
        create(:goal, parent: campaign, goalable: place, kpi: Kpi.events, value: 2)
        create(:goal, parent: campaign, goalable: place, kpi: Kpi.promo_hours, value: 4)
        create(:goal, parent: campaign, goalable: place, kpi: Kpi.expenses, value: 50)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place)
        create_list(:attached_asset, 2, attachable: event1, asset_type: 'photo')
        event1.result_for_kpi(kpi).value = '25'
        event1.save
        event1.users << company_user

        event2 = create(:submitted_event, company: company, campaign: campaign, place: place)
        event2.result_for_kpi(kpi).value = '20'
        event2.save
        event2.users << company_user

        event3 = create(:rejected_event, company: company, campaign: campaign, place: place)
        event3.result_for_kpi(kpi).value = '33'
        event3.save
        event3.users << company_user

        ### Setting data to test Activities
        activity_type = create(:activity_type, name: 'Activity Type', company: company)
        campaign.activity_types << activity_type

        # Activities settings for Place
        area1 = create(:area, name: 'Area 1', company: company)
        area2 = create(:area, name: 'Area 2', company: company)
        place1 = create(:place, name: 'Place 1')
        place2 = create(:place, name: 'Place 2')
        area1.places << place1
        area2.places << place2
        campaign.areas << [area1, area2]
        company_user.areas << [area1, area2]
        venue1 = create(:venue, place: place1, company: company)
        venue2 = create(:venue, place: place2, company: company)
        event4 = create(:approved_event, company: company, campaign: campaign, place: another_place)
        # Activities settings for Staff
        another_user = create(:company_user, company: company)
        team1 = create(:team, name: 'Team 1', company: company)
        team1.users << another_user
        event1.teams << team1
        campaign.teams << team1

        # Activities goals for Place
        create(:goal, parent: campaign, goalable: area1, activity_type_id: activity_type.id, value: 5)
        create(:goal, parent: campaign, goalable: area2, activity_type_id: activity_type.id, value: 10)
        create(:goal, parent: campaign, goalable: another_place, activity_type_id: activity_type.id, value: 7)
        # Activities goals for Staff
        create(:goal, parent: campaign, goalable: team1, activity_type_id: activity_type.id, value: 8)

        # Activities for Place
        create(:activity, activity_type: activity_type, activitable: venue1, campaign: campaign,
                          company_user: company_user, activity_date: '2013-07-22')
        create(:activity, activity_type: activity_type, activitable: venue1, campaign: campaign,
                          company_user: company_user, activity_date: '2013-07-23')
        create(:activity, activity_type: activity_type, activitable: venue2, campaign: campaign,
                          company_user: company_user, activity_date: '2013-07-24')
        create(:activity, activity_type: activity_type, activitable: event4, campaign: campaign,
                          company_user: company_user, activity_date: '2013-07-25')
        # Activities for Staff
        create(:activity, activity_type: activity_type, activitable: venue2, campaign: campaign,
                          company_user: another_user, activity_date: '2013-07-26')
        create(:activity, activity_type: activity_type, activitable: event1, campaign: campaign,
                          company_user: another_user, activity_date: '2013-07-27')

        Sunspot.commit

        visit analysis_gva_path

        choose_campaign('Test Campaign FY01')

        ### Testing group by Campaign
        within('.kpi-trend:nth-child(1)') do
          expect(page).to have_content('Samples')
          find('.progress').trigger('mouseover')
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

        within('.kpi-trend:nth-child(2)') do
          expect(page).to have_content('Photos')
          find('.progress').trigger('mouseover')
          expect(page).to have_selector('.executed-label', text: '2')
          expect(page).to have_selector('.submitted-label', text: '0')
          expect(page).to have_selector('.rejected-label', text: '0')
          expect(page).to have_content('10 GOAL')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('20%')
            expect(page).to have_content('2 OF 10 GOAL')
          end
        end

        ### Testing group by Place
        report_form.find('label', text: 'Place').click

        within('#gva-result-Place' + place.id.to_s + ' .item-summary') do
          expect(page).to have_content('The Place')
          within('.goals-summary') do
            expect(page).to have_content('50% EVENTS')
            expect(page).to have_content('50% PROMO HOURS')
            expect(page).to have_content('0% EXPENSES')
            expect(page).to have_content('52% SAMPLES')
          end
        end

        within('#gva-result-Place' + place.id.to_s + ' .accordion-heading') do
          click_js_link('The Place')
        end
        within('#gva-result-Place' + place.id.to_s + ' .kpi-trend:nth-child(3)') do
          expect(page).to have_content('Samples')
          find('.progress').trigger('mouseover')
          expect(page).to have_selector('.executed-label', text: '25')
          expect(page).to have_selector('.submitted-label', text: '20')
          expect(page).to have_selector('.rejected-label', text: '33')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('52%')
            expect(page).to have_content('78 OF 150 GOAL')
          end
        end
        within('#gva-result-Place' + place.id.to_s + ' .accordion-heading') do
          click_js_link('The Place')
        end

        within('#gva-result-Place' + another_place.id.to_s + ' .accordion-heading') do
          click_js_link('Place 3')
        end
        within('#gva-result-Place' + another_place.id.to_s + ' .kpi-trend:nth-child(1)') do
          expect(page).to have_content('Activity Type')
          find('.progress').trigger('mouseover')
          expect(page).to have_selector('.executed-label', text: '1')
          expect(page).to have_selector('.submitted-label', text: '0')
          expect(page).to have_selector('.rejected-label', text: '0')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('14%')
            expect(page).to have_content('1 OF 7 GOAL')
          end
        end
        within('#gva-result-Place' + another_place.id.to_s + ' .accordion-heading') do
          click_js_link('Place 3')
        end

        # Checking that activities for Venues are in the corresponding Area only
        within('#gva-result-Area' + area1.id.to_s + ' .accordion-heading') do
          click_js_link('Area 1')
        end
        within('#gva-result-Area' + area1.id.to_s + ' .kpi-trend:nth-child(1)') do
          expect(page).to have_content('Activity Type')
          find('.progress').trigger('mouseover')
          expect(page).to have_selector('.executed-label', text: '2')
          expect(page).to have_selector('.submitted-label', text: '0')
          expect(page).to have_selector('.rejected-label', text: '0')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('40%')
            expect(page).to have_content('2 OF 5 GOAL')
          end
        end
        within('#gva-result-Area' + area1.id.to_s + ' .accordion-heading') do
          click_js_link('Area 1')
        end

        within('#gva-result-Area' + area2.id.to_s + ' .accordion-heading') do
          click_js_link('Area 2')
        end
        within('#gva-result-Area' + area2.id.to_s + ' .kpi-trend:nth-child(1)') do
          expect(page).to have_content('Activity Type')
          find('.progress').trigger('mouseover')
          expect(page).to have_selector('.executed-label', text: '2')
          expect(page).to have_selector('.submitted-label', text: '0')
          expect(page).to have_selector('.rejected-label', text: '0')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('20%')
            expect(page).to have_content('2 OF 10 GOAL')
          end
        end

        ### Testing group by Staff
        report_form.find('label', text: 'Staff').click

        within('#gva-result-CompanyUser' + company_user.id.to_s + ' .item-summary') do
          expect(page).to have_content('Juanito Bazooka')
          within('.goals-summary') do
            expect(page).to have_content('100% EVENTS')
            expect(page).to have_content('78% SAMPLES')
          end
        end

        within('#gva-result-CompanyUser' + company_user.id.to_s + ' .accordion-heading') do
          click_js_link('Juanito Bazooka')
        end
        within('#gva-result-CompanyUser' + company_user.id.to_s + ' .kpi-trend:nth-child(2)') do
          expect(page).to have_content('Samples')
          find('.progress').trigger('mouseover')
          expect(page).to have_selector('.executed-label', text: '25')
          expect(page).to have_selector('.submitted-label', text: '20')
          expect(page).to have_selector('.rejected-label', text: '33')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('78%')
            expect(page).to have_content('78 OF 100 GOAL')
          end
        end
        within('#gva-result-CompanyUser' + company_user.id.to_s + ' .accordion-heading') do
          click_js_link('Juanito Bazooka')
        end

        # Checking that activities for Venues are in the corresponding Team only
        within('#gva-result-Team' + team1.id.to_s + ' .accordion-heading') do
          click_js_link('Team 1')
        end
        within('#gva-result-Team' + team1.id.to_s + ' .kpi-trend:nth-child(1)') do
          expect(page).to have_content('Activity Type')
          find('.progress').trigger('mouseover')
          expect(page).to have_selector('.executed-label', text: '2')
          expect(page).to have_selector('.submitted-label', text: '0')
          expect(page).to have_selector('.rejected-label', text: '0')
          expect(page).to have_css('.today-line-indicator')
          within('.progress-label') do
            expect(page).to have_content('25%')
            expect(page).to have_content('2 OF 8 GOAL')
          end
        end
      end

      scenario 'should remove items from GvA results' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', company: company)
        kpi = create(:kpi, name: 'Interactions', company: company)
        campaign.add_kpi kpi

        place = create(:place, name: 'Place 1')
        campaign.places << place
        company_user.campaigns << campaign
        company_user.places << place

        create(:goal, goalable: campaign, kpi: kpi)
        create(:goal, parent: campaign, goalable: place, kpi: kpi)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place)
        event1.save

        visit analysis_gva_path

        report_form.find('label', text: 'Place').click

        choose_campaign('Test Campaign FY01')

        within('#gva-results') do
          expect(page).to have_content('Place 1')
          within('.accordion-heading') do
            click_js_link('Remove Place 1')
          end
          expect(page).to_not have_content('Place 1')
        end
      end

      scenario 'should display the places GvA stats for selected campaign whithout select group by when it is the unique permission' do
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', company: company)
        kpi = create(:kpi, name: 'Interactions', company: company)
        campaign.add_kpi kpi

        place = create(:place, name: 'Place 1')
        campaign.places << place
        company_user.campaigns << campaign
        company_user.places << place

        create(:goal, goalable: campaign, kpi: kpi)
        create(:goal, parent: campaign, goalable: place, kpi: kpi)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place)
        event1.save

        visit analysis_gva_path

        choose_campaign('Test Campaign FY01')

        within('#gva-results') do
          expect(page).to have_content('Place 1')
        end
      end

      scenario 'should export the overall campaign GvA to Excel' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        campaign.add_kpi Kpi.samples
        campaign.add_kpi Kpi.events

        place1 = create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        create(:goal, goalable: campaign, kpi: Kpi.samples, value: '100')
        create(:goal, goalable: campaign, kpi: Kpi.events, value: '2')

        event1 = create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(Kpi.samples).value = '25'
        event1.save

        event2 = create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(Kpi.samples).value = '20'
        event2.save

        visit analysis_gva_path

        choose_campaign('Test Campaign FY01')

        # Export
        export_report

        expect(ListExport.last).to have_rows([
          ['METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %'],
          ['Events', '2', '1', '50.00%', '2', '100.00%'],
          ['Samples', '100', '25', '25.00%', '45', '45.00%']
        ])
      end

      scenario 'should export the GvA grouped by Place to Excel' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        kpi2 = Kpi.events
        campaign.add_kpi kpi
        campaign.add_kpi kpi2

        place1 = create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        create(:goal, parent: campaign, goalable: place1, kpi: kpi, value: 150)
        create(:goal, parent: campaign, goalable: place1, kpi: kpi2, value: 2)
        create(:goal, parent: campaign, goalable: place1, kpi: Kpi.promo_hours, value: 4)
        create(:goal, parent: campaign, goalable: place1, kpi: Kpi.expenses, value: 50)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        visit analysis_gva_path

        choose_campaign('Test Campaign FY01')

        report_form.find('label', text: 'Place').click

        # Export
        export_report

        expect(ListExport.last).to have_rows([
          ['PLACE/AREA', 'METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %'],
          ['Place 1', 'Events', '2', '1', '50.00%', '2', '100.00%'],
          ['Place 1', 'Promo Hours', '4', '2', '50.00%', '4', '100.00%'],
          ['Place 1', 'Samples', '150', '25', '16.67%', '45', '30.00%']
        ])
      end

      scenario 'should export the GvA grouped by Staff to Excel' do
        company_user.role.permissions.create(action: :gva_report_campaigns, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_places, subject_class: 'Campaign', mode: 'campaigns')
        company_user.role.permissions.create(action: :gva_report_users, subject_class: 'Campaign', mode: 'campaigns')
        campaign = create(:campaign, name: 'Test Campaign FY01', start_date: '07/21/2013', end_date: '03/30/2014', company: company)
        kpi = Kpi.samples
        kpi2 = Kpi.events
        campaign.add_kpi kpi
        campaign.add_kpi kpi2

        place1 = create(:place, name: 'Place 1')
        campaign.places << place1
        company_user.campaigns << campaign
        company_user.places << place1

        create(:goal, parent: campaign, goalable: company_user, kpi: kpi, value: 50)
        create(:goal, parent: campaign, goalable: company_user, kpi: kpi2, value: 1)

        event1 = create(:approved_event, company: company, campaign: campaign, place: place1)
        event1.result_for_kpi(kpi).value = '25'
        event1.save

        event2 = create(:submitted_event, company: company, campaign: campaign, place: place1)
        event2.result_for_kpi(kpi).value = '20'
        event2.save

        event1.users << company_user
        event2.users << company_user

        visit analysis_gva_path

        choose_campaign('Test Campaign FY01')

        report_form.find('label', text: 'Staff').click

        # Export
        export_report

        expect(ListExport.last).to have_rows([
          ['USER/TEAM', 'METRIC', 'GOAL', 'ACTUAL', 'ACTUAL %', 'PENDING', 'PENDING %'],
          ['Juanito Bazooka', 'Events', '1', '1', '100.00%', '2', '200.00%'],
          ['Juanito Bazooka', 'Samples', '50', '25', '50.00%', '45', '90.00%']
        ])
      end
    end
  end

  def report_form
    find('form#report-settings')
  end

  def choose_campaign(name)
    select_from_chosen(name, from: 'report[campaign_id]')
  end

  def export_report(format = 'CSV')
    expect do
      click_js_link('Download')
      click_js_link("Download as #{format}")
      wait_for_export_to_complete
    end.to change(ListExport, :count).by(1)
  end
end
